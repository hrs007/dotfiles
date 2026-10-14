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

local function open_related_file()
    local file = vim.api.nvim_buf_get_name(0)
    local ft = vim.bo.filetype
    if file == "" or ft == "oil" or ft == "help" or ft == "qf" or ft == "terminal" then
        vim.notify("Open a source, Python, or web file first.", vim.log.levels.INFO)
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
        prompt = "Related files  ·  " .. vim.fn.fnamemodify(root, ":~"),
        format_item = function(path)
            return path:gsub("^" .. vim.pesc(root .. package.config:sub(1, 1)), "")
        end,
    }, function(path)
        if path then open(path) end
    end)
end

vim.keymap.set("n", "<leader>cF", open_related_file, {
    desc = "Code: Open related file",
})

return { open = open_related_file }
