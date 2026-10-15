-- Persistent C# analyzer profiles backed by project-local EditorConfig rules.
local M = {}

local state_path = vim.fs.joinpath(vim.fn.stdpath("state"), "csharp-diagnostics.json")
local begin_marker = "# >>> Neovim C# diagnostics profile >>>"
local end_marker = "# <<< Neovim C# diagnostics profile <<<"
local profiles = {
    quiet = {
        order = 1,
        label = "1 · Core errors (quiet)",
        description = "least strict: show compiler errors only; hide analyzer findings",
    },
    basic = {
        order = 2,
        label = "2 · Suggestions (basic)",
        severity = "suggestion",
        description = "show analyzer findings as suggestions; no warning promotion",
    },
    standard = {
        order = 3,
        label = "3 · Project defaults (standard)",
        description = "remove the override and follow the project configuration",
    },
    strict = {
        order = 4,
        label = "4 · Analyzer warnings (strict)",
        severity = "warning",
        description = "most strict: promote analyzer and code-style findings to warnings",
    },
}

local selected_by_root = {}
do
    local file = io.open(state_path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local ok, saved = pcall(vim.json.decode, content)
        if ok and type(saved) == "table" then
            selected_by_root = saved
        end
    end
end

local function normalize(path)
    path = vim.fs.normalize(vim.fn.expand(path or "")):gsub("\\", "/")
    return vim.fn.has("win32") == 1 and path:lower() or path
end

local function project_root_from_path(path)
    path = vim.fn.expand(path or "")
    if path == "" then
        return normalize(vim.fn.getcwd())
    end
    local start = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
    local project = require("config.project")
    local solution = project.find_solution(start)
    if solution then
        return normalize(vim.fs.dirname(solution))
    end
    local root = vim.fs.root(start, {
        ".editorconfig",
        ".slnx",
        ".sln",
        ".csproj",
        "Directory.Build.props",
        ".git",
    })
    local csproj = project.find_csproj(start)
    return normalize(root or (csproj and vim.fs.dirname(csproj)) or start)
end

local function project_root(bufnr)
    local file = vim.api.nvim_buf_get_name(bufnr)
    if vim.bo[bufnr].filetype == "oil" then
        local ok, directory = pcall(function()
            return require("oil").get_current_dir()
        end)
        return project_root_from_path(ok and directory or vim.fn.getcwd())
    end
    return project_root_from_path(file)
end

local function editorconfig_path(root)
    return vim.fs.joinpath(root, ".editorconfig")
end

local function read_lines(path)
    if vim.fn.filereadable(path) == 1 then
        return vim.fn.readfile(path)
    end
    return {}
end

local function write_profile_rule(root, profile)
    local path = editorconfig_path(root)
    local had_file = vim.fn.filereadable(path) == 1
    local lines = read_lines(path)
    local kept, inside_block = {}, false
    for _, line in ipairs(lines) do
        if line == begin_marker then
            inside_block = true
        elseif line == end_marker then
            inside_block = false
        elseif not inside_block then
            kept[#kept + 1] = line
        end
    end

    if profile.severity then
        if #kept > 0 and kept[#kept] ~= "" then
            kept[#kept + 1] = ""
        end
        kept[#kept + 1] = begin_marker
        kept[#kept + 1] = "[*.cs]"
        kept[#kept + 1] = "dotnet_analyzer_diagnostic.severity = " .. profile.severity
        kept[#kept + 1] = end_marker
    end

    if #kept == 0 and not profile.severity and not had_file then
        return true, path
    end
    vim.fn.mkdir(root, "p")
    if vim.fn.writefile(kept, path) ~= 0 then
        return false, path
    end
    return true, path
end

local function save_state()
    local ok, encoded = pcall(vim.json.encode, selected_by_root)
    if not ok then
        return false
    end
    vim.fn.mkdir(vim.fs.dirname(state_path), "p")
    return vim.fn.writefile({ encoded }, state_path) == 0
end

function M.profile_for_root(root)
    root = normalize(root)
    local name = selected_by_root[root] or "quiet"
    return name, profiles[name] or profiles.standard
end

function M.apply_profile(root, profile_name, bufnr)
    root = normalize(root)
    local profile = profiles[profile_name]
    if not profile then
        vim.notify("Unknown C# diagnostics profile: " .. tostring(profile_name), vim.log.levels.ERROR)
        return false
    end

    local ok, path = write_profile_rule(root, profile)
    if not ok then
        vim.notify("Could not update " .. path, vim.log.levels.ERROR)
        return false
    end

    selected_by_root[root] = profile_name
    if not save_state() then
        vim.notify("C# profile was written, but its selection could not be saved.", vim.log.levels.ERROR)
        return false
    end

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local refresh_buffers, seen_clients = {}, {}
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "cs" then
        refresh_buffers[#refresh_buffers + 1] = bufnr
    else
        for _, candidate in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(candidate)
                and vim.bo[candidate].filetype == "cs"
                and project_root(candidate) == root
            then
                refresh_buffers[#refresh_buffers + 1] = candidate
            end
        end
    end

    local uri = vim.uri_from_fname(path)
    for _, target_buf in ipairs(refresh_buffers) do
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = target_buf })) do
            if not seen_clients[client.id] then
                seen_clients[client.id] = true
                client:notify("workspace/didChangeWatchedFiles", {
                    changes = { { uri = uri, type = 2 } },
                })
                client:notify("workspace/didChangeConfiguration", {
                    settings = client.config.settings or {},
                })
            end
        end
    end

    -- Re-filter the most recent Roslyn publications immediately using the new
    -- profile. The watched-file notification also prompts the server to
    -- recompute analyzer results from the updated .editorconfig.
    vim.schedule(function()
        local ok, diagnostics = pcall(require, "config.diagnostics")
        if ok then
            diagnostics.refresh_cached_publications()
            for _, target_buf in ipairs(refresh_buffers) do
                if vim.api.nvim_buf_is_valid(target_buf) then
                    diagnostics.refresh_roslyn(target_buf)
                end
            end
        end
    end)

    vim.notify(
        ("C# checks for %s: %s (%s)"):format(
            vim.fn.fnamemodify(root, ":~"),
            profile.label,
            profile.description
        ),
        vim.log.levels.INFO
    )
    return true
end

function M.apply_profile_for_buffer(bufnr, profile_name)
    return M.apply_profile(project_root(bufnr), profile_name, bufnr)
end

function M.apply_profile_for_path(path, profile_name, bufnr)
    return M.apply_profile(project_root_from_path(path), profile_name, bufnr)
end

local function open_profile_picker(root, bufnr)
    local current, current_profile = M.profile_for_root(root)
    local ordered = { "quiet", "basic", "standard", "strict" }
    local choices = {}
    for _, name in ipairs(ordered) do
        local profile = profiles[name]
        choices[#choices + 1] = {
            name = name,
            order = profile.order,
            current = name == current,
            label = profile.label,
            description = profile.description,
        }
    end

    local function apply(choice)
        if choice then
            M.apply_profile(root, choice.name, bufnr)
        end
    end

    local ok, pickers = pcall(require, "telescope.pickers")
    if ok then
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local previewers = require("telescope.previewers")
        pickers.new({}, {
            prompt_title = "C# Diagnostics · " .. vim.fn.fnamemodify(root, ":~"),
            results_title = "Type to filter · Enter select · Esc cancel · current: " .. current_profile.label,
            finder = finders.new_table({
                results = choices,
                entry_maker = function(choice)
                    local marker = choice.current and "  ✓" or ""
                    local display = ("%d  %-30s%s"):format(
                        choice.order,
                        choice.label,
                        marker
                    )
                    return {
                        value = choice,
                        display = display,
                        ordinal = choice.label .. " " .. choice.description,
                    }
                end,
            }),
            sorter = conf.generic_sorter({}),
            previewer = previewers.new_buffer_previewer({
                title = "Profile details",
                define_preview = function(self, entry)
                    local choice = entry.value
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
                        choice.label,
                        "",
                        choice.description,
                        "",
                        "Compiler errors stay visible in every tier.",
                        "Analyzer and code-style findings increase by tier.",
                    })
                end,
            }),
            sorting_strategy = "ascending",
            layout_strategy = "horizontal",
            layout_config = {
                width = 0.74,
                height = 0.50,
                preview_width = 0.42,
            },
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selected = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    apply(selected and selected.value or nil)
                end)
                return true
            end,
        }):find()
        return
    end

    vim.ui.select(choices, {
        prompt = "C# diagnostics · current: " .. current_profile.label,
        format_item = function(choice)
            return ("%d  %s — %s%s"):format(
                choice.order,
                choice.label,
                choice.description,
                choice.current and " · current" or ""
            )
        end,
    }, apply)
end

function M.select_profile(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    open_profile_picker(project_root(bufnr), bufnr)
end

function M.select_profile_for_path(path, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local root = project_root_from_path(path)
    local project = require("config.project").find_csproj(path)
    if not project then
        vim.notify("No C# project found in this folder or its parents.", vim.log.levels.INFO)
        return
    end
    M.select_profile_for_root(root, bufnr)
end

function M.select_profile_for_root(root, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    open_profile_picker(normalize(root), bufnr)
end

return M
