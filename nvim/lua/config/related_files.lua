-- Find source, header, style, and test companions by their shared filename.
local Project = require("config.project")

local ignored = {
    [".git"] = true,
    ["node_modules"] = true,
    ["vendor"] = true,
    ["build"] = true,
    ["dist"] = true,
    ["target"] = true,
    [".venv"] = true,
    ["venv"] = true,
    ["__pycache__"] = true,
}

local function project_root(start)
    local markers = {
        [".git"] = true,
        ["package.json"] = true,
        ["CMakeLists.txt"] = true,
        ["Makefile"] = true,
        ["pyproject.toml"] = true,
        ["Cargo.toml"] = true,
        ["go.mod"] = true,
    }
    local marker = Project.find_upward(start, function(name) return markers[name] == true end)
    return marker and vim.fs.dirname(marker) or start
end

local function add(names, value)
    names[value] = true
end

local function base_name(name)
    local stem = name:gsub("%.[^.]+$", "")
    for _, suffix in ipairs({ ".test", ".spec", ".stories", ".module" }) do
        if stem:sub(-#suffix) == suffix then
            stem = stem:sub(1, -#suffix - 1)
        end
    end
    return stem
end

local function candidate_names(ft, file_name)
    local names = {}
    local stem = base_name(file_name)

    if ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" then
        for _, extension in ipairs({ ".h", ".hh", ".hpp", ".hxx", ".c", ".cc", ".cpp", ".cxx", ".cu", ".cuh", ".m", ".mm" }) do
            add(names, stem .. extension)
        end
    elseif ft == "python" then
        add(names, stem .. ".py")
        add(names, "test_" .. stem .. ".py")
        add(names, stem .. "_test.py")
        local test_stem = stem:match("^test_(.+)$") or stem:match("^(.+)_test$")
        if test_stem then add(names, test_stem .. ".py") end
    elseif ft == "javascript" or ft == "javascriptreact" or ft == "typescript"
        or ft == "typescriptreact" or ft == "css" or ft == "scss" or ft == "html" then
        local script_extensions = { ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs" }
        for _, extension in ipairs(script_extensions) do
            add(names, stem .. extension)
            add(names, stem .. ".test" .. extension)
            add(names, stem .. ".spec" .. extension)
            add(names, stem .. ".stories" .. extension)
        end
        for _, extension in ipairs({ ".css", ".scss", ".sass", ".less" }) do
            add(names, stem .. extension)
            add(names, stem .. ".module" .. extension)
        end
        add(names, stem .. ".html")
    end

    return names
end

local function find_related_files(root, names)
    local rg = vim.fn.exepath("rg")
    if rg == "" then
        vim.notify("Related-file search needs ripgrep (rg).", vim.log.levels.ERROR)
        return {}
    end

    local command = { rg, "--files", "--hidden" }
    for directory in pairs(ignored) do
        table.insert(command, "--glob")
        table.insert(command, "!**/" .. directory .. "/**")
    end
    for name in pairs(names) do
        table.insert(command, "--glob")
        table.insert(command, name)
    end
    table.insert(command, root)

    local results = vim.fn.systemlist(command)
    if vim.v.shell_error ~= 0 and #results == 0 then return {} end

    local files = {}
    for _, path in ipairs(results) do
        path = vim.fs.normalize(path)
        if vim.fn.filereadable(path) == 1 then
            table.insert(files, path)
        end
    end
    table.sort(files)
    return files
end

local web_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    css = true,
    scss = true,
    html = true,
}

local function relation_label(path)
    local name = vim.fs.basename(path)
    if name:match("%.test%.") or name:match("%.spec%.") then return "Test" end
    if name:match("%.stories%.") then return "Story" end
    if name:match("%.module%.") or name:match("%.css$") or name:match("%.scss$")
        or name:match("%.sass$") or name:match("%.less$") then
        return "Style"
    end
    if name:match("%.html$") then return "Markup" end
    return "Component"
end

local function open_related_file(web_only)
    local file = vim.api.nvim_buf_get_name(0)
    local ft = vim.bo.filetype
    if file == "" or ft == "oil" or ft == "help" or ft == "qf" or ft == "terminal" then
        vim.notify("Open a source, Python, or web file first.", vim.log.levels.INFO)
        return
    end
    if web_only and not web_filetypes[ft] then
        vim.notify("Open a JavaScript, TypeScript, stylesheet, or HTML file first.", vim.log.levels.INFO)
        return
    end

    local names = candidate_names(ft, vim.fs.basename(file))
    if not next(names) then
        vim.notify("Related-file search is not configured for " .. (ft ~= "" and ft or "this filetype") .. ".", vim.log.levels.INFO)
        return
    end

    local root = project_root(vim.fs.dirname(file))
    local current = vim.fs.normalize(file)
    local files = vim.tbl_filter(function(path) return path ~= current end, find_related_files(root, names))
    if #files == 0 then
        vim.notify("No related files found in " .. vim.fn.fnamemodify(root, ":~"), vim.log.levels.INFO)
        return
    end

    local function open(path)
        vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
    if #files == 1 then
        open(files[1])
        return
    end

    vim.ui.select(files, {
        prompt = (web_only and "Component files" or "Related files") .. "  ·  " .. vim.fn.fnamemodify(root, ":~"),
        format_item = function(path)
            local relative = path:gsub("^" .. vim.pesc(root .. package.config:sub(1, 1)), "")
            return (web_only and ("[%-9s] %s"):format(relation_label(path), relative)) or relative
        end,
    }, function(path)
        if path then open(path) end
    end)
end

local import_patterns = {
    "from%s+(['\"])(.-)%1",
    "import%s*(['\"])(.-)%1",
    "import%s*%(%s*(['\"])(.-)%1",
    "require%s*%(%s*(['\"])(.-)%1",
    "@import%s+(['\"])(.-)%1",
}

local function import_at_cursor(line, cursor_col)
    local matches = {}
    for _, pattern in ipairs(import_patterns) do
        local first, last, _, specifier = line:find(pattern)
        if first and specifier and specifier ~= "" then
            local path_start = line:find(specifier, first, true)
            if path_start then
                matches[#matches + 1] = {
                    path = specifier,
                    first = path_start - 1,
                    last = path_start - 1 + #specifier,
                }
            end
        end
    end
    for _, match in ipairs(matches) do
        if cursor_col >= match.first and cursor_col <= match.last then
            return match.path
        end
    end
    if #matches == 1 then return matches[1].path end
end

local function tsconfig_aliases(start)
    local config = Project.find_upward(start, function(name)
        return name == "tsconfig.json" or name == "jsconfig.json"
    end)
    if not config then return {} end
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(config), "\n"))
    if not ok or type(decoded) ~= "table" then return {} end
    local compiler = decoded.compilerOptions or {}
    local config_dir = vim.fs.dirname(config)
    local base_url = vim.fs.normalize(vim.fs.joinpath(config_dir, compiler.baseUrl or "."))
    local aliases = {}
    for pattern, targets in pairs(compiler.paths or {}) do
        local prefix, suffix = pattern:match("^(.-)%*(.-)$")
        if not prefix then prefix, suffix = pattern, "" end
        aliases[#aliases + 1] = {
            prefix = prefix,
            suffix = suffix,
            wildcard = pattern:find("*", 1, true) ~= nil,
            base_url = base_url,
            targets = type(targets) == "table" and targets or {},
        }
    end
    return aliases
end

local function alias_middle(alias, specifier)
    if alias.wildcard then
        if specifier:sub(1, #alias.prefix) ~= alias.prefix
            or (alias.suffix ~= "" and specifier:sub(-#alias.suffix) ~= alias.suffix)
        then
            return nil
        end
        return specifier:sub(#alias.prefix + 1, #specifier - #alias.suffix)
    end
    if specifier == alias.prefix then return "" end
end

local function import_bases(specifier, file, root)
    local bases = {}
    local function add(path)
        path = vim.fs.normalize(path)
        if not vim.tbl_contains(bases, path) then bases[#bases + 1] = path end
    end

    if specifier:match("^%.") then
        add(vim.fs.joinpath(vim.fs.dirname(file), specifier))
    elseif specifier:match("^/") then
        add(vim.fs.joinpath(root, specifier:sub(2)))
    else
        for _, alias in ipairs(tsconfig_aliases(vim.fs.dirname(file))) do
            local middle = alias_middle(alias, specifier)
            if middle then
                for _, target in ipairs(alias.targets) do
                    local mapped = target:gsub("%*", middle)
                    add(vim.fs.joinpath(alias.base_url, mapped))
                end
            end
        end
        -- Support the common Vite/TS `@/` -> `src/` convention even when the
        -- project has no readable tsconfig alias declaration.
        if specifier:sub(1, 2) == "@/" then
            add(vim.fs.joinpath(root, "src", specifier:sub(3)))
            add(vim.fs.joinpath(root, specifier:sub(3)))
        end
    end
    return bases
end

local function existing_import(base, ft)
    if vim.fn.filereadable(base) == 1 then return base end
    local preferred = {
        javascript = { ".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx" },
        javascriptreact = { ".jsx", ".js", ".tsx", ".ts", ".mjs", ".cjs" },
        typescript = { ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs" },
        typescriptreact = { ".tsx", ".ts", ".jsx", ".js", ".mjs", ".cjs" },
        css = { ".css", ".scss", ".sass", ".less" },
        scss = { ".scss", ".css", ".sass", ".less" },
        html = { ".html", ".vue", ".svelte" },
    }
    local extensions = preferred[ft] or {}
    for _, extension in ipairs({ ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".json", ".vue", ".svelte", ".css", ".scss", ".sass", ".less" }) do
        if not vim.tbl_contains(extensions, extension) then extensions[#extensions + 1] = extension end
    end
    for _, extension in ipairs(extensions) do
        local candidate = base .. extension
        if vim.fn.filereadable(candidate) == 1 then return candidate end
    end
    if vim.fn.isdirectory(base) == 1 then
        for _, extension in ipairs(extensions) do
            local candidate = vim.fs.joinpath(base, "index" .. extension)
            if vim.fn.filereadable(candidate) == 1 then return candidate end
        end
    end
end

local function open_import_file(path)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function create_import_file(path)
    local directory = vim.fs.dirname(path)
    if vim.fn.mkdir(directory, "p") == 0 and vim.fn.isdirectory(directory) ~= 1 then
        vim.notify("Could not create import directory: " .. directory, vim.log.levels.ERROR)
        return
    end
    local ok, err = pcall(vim.fn.writefile, {}, path)
    if not ok then
        vim.notify("Could not create import file: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    open_import_file(path)
end

local function open_import()
    local file = vim.api.nvim_buf_get_name(0)
    local ft = vim.bo.filetype
    if file == "" or not web_filetypes[ft] then
        vim.notify("Open a JavaScript, TypeScript, stylesheet, or HTML file first.", vim.log.levels.INFO)
        return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, cursor_col = cursor[1], cursor[2]
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
    local specifier = import_at_cursor(line, cursor_col)
    if not specifier then
        vim.notify("Place the cursor on an import path first.", vim.log.levels.INFO)
        return
    end

    local local_path = specifier:match("^%.") or specifier:match("^/")
        or specifier:sub(1, 2) == "@/"
    local root = project_root(vim.fs.dirname(file))
    if not local_path then
        for _, alias in ipairs(tsconfig_aliases(vim.fs.dirname(file))) do
            if alias_middle(alias, specifier) ~= nil then
                local_path = true
                break
            end
        end
    end
    if not local_path then
        vim.notify("'" .. specifier .. "' looks like a package import, not a local file.", vim.log.levels.INFO)
        return
    end

    local bases = import_bases(specifier, file, root)
    for _, base in ipairs(bases) do
        local found = existing_import(base, ft)
        if found then
            open_import_file(found)
            return
        end
    end

    local choices, seen = {}, {}
    local explicit_extension = specifier:match("%.[%w]+$") ~= nil
    local extension = ({
        javascript = ".js", javascriptreact = ".jsx", typescript = ".ts",
        typescriptreact = ".tsx", css = ".css", scss = ".scss", html = ".html",
    })[ft] or ".ts"
    for _, base in ipairs(bases) do
        local path = explicit_extension and base or base .. extension
        if not seen[path] then
            seen[path] = true
            choices[#choices + 1] = path
        end
    end
    if #choices == 0 then
        vim.notify("Could not resolve local import: " .. specifier, vim.log.levels.WARN)
        return
    end

    vim.ui.select(choices, {
        prompt = "Import file not found · create",
        format_item = function(path)
            return path:gsub("^" .. vim.pesc(root .. package.config:sub(1, 1)), "")
        end,
    }, function(path)
        if path then create_import_file(path) end
    end)
end

-- Open a local path under the cursor (including markup attributes such as
-- src="/src/main.tsx"). Root-relative web paths resolve from the project root.
local function open_path_or_url()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1] or ""
    local col = cursor[2] + 1
    local target

    -- Prefer the full quoted value when the cursor is inside an HTML/JSX
    -- attribute, so URLs retain their scheme and local paths retain slashes.
    for _, quote in ipairs({ '"', "'" }) do
        local pattern = quote == '"' and '()"([^"]*)"()' or "()'([^']*)'()"
        for first, value, last in line:gmatch(pattern) do
            if first < col and col <= last then
                target = value
                break
            end
        end
        if target then break end
    end
    if not target then
        target = vim.fn.expand("<cfile>")
    end
    if target == "" then
        vim.notify("Place the cursor on a path or URL first.", vim.log.levels.INFO)
        return
    end

    if target:match("^https?://") then
        if vim.ui.open then
            vim.ui.open(target)
        else
            vim.fn["netrw#BrowseX"](target, 0)
        end
        return
    end

    target = target:gsub("[?#].*$", "")

    local file = vim.api.nvim_buf_get_name(0)
    local start = file ~= "" and vim.fs.dirname(file) or Project.current_dir()
    local root = project_root(start)
    local candidates = {}
    if target:sub(1, 1) == "/" then
        candidates[#candidates + 1] = vim.fs.joinpath(root, target:sub(2))
    else
        candidates[#candidates + 1] = vim.fs.joinpath(start, target)
        candidates[#candidates + 1] = vim.fs.joinpath(root, target)
    end
    for _, path in ipairs(candidates) do
        if vim.fn.filereadable(path) == 1 then
            local bufnr = vim.fn.bufadd(path)
            vim.fn.bufload(bufnr)
            vim.api.nvim_win_set_buf(0, bufnr)
            return
        end
    end
    vim.notify("Could not find local file: " .. target, vim.log.levels.WARN)
end

vim.keymap.set("n", "gx", open_path_or_url, {
    desc = "Open path under cursor (or URL)",
})

vim.keymap.set("n", "<leader>cF", open_related_file, {
    desc = "Code: Open related file",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "scss", "html" },
    callback = function(event)
        vim.keymap.set("n", "<leader>cC", function() open_related_file(true) end, {
            buffer = event.buf,
            desc = "Web: Navigate component, style, story, or test",
        })
        vim.keymap.set("n", "<leader>cI", open_import, {
            buffer = event.buf,
            desc = "Web: Open or create import file",
        })
    end,
})

return { open = open_related_file, open_import = open_import, open_path_or_url = open_path_or_url }
