-- Configure diagnostics and provide persistent, source-aware rule filters.
local M = {}

local diagnostic_signs = {
    text = {
        [vim.diagnostic.severity.ERROR] = "E",
        [vim.diagnostic.severity.WARN] = "W",
        [vim.diagnostic.severity.INFO] = "I",
        [vim.diagnostic.severity.HINT] = "H",
    },
}

local visibility_state_path = vim.fs.joinpath(vim.fn.stdpath("state"), "diagnostic-visibility.json")
local function read_visibility_state()
    if vim.fn.filereadable(visibility_state_path) ~= 1 then
        return {}
    end
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(visibility_state_path), "\n"))
    return ok and type(decoded) == "table" and decoded or {}
end

local visibility_state = read_visibility_state()
local hidden_severities = {
    [vim.diagnostic.severity.ERROR] = visibility_state.errors_hidden == true,
    -- Start in a quiet, errors-first mode. An explicit user choice remains
    -- persistent once saved in diagnostic-visibility.json.
    [vim.diagnostic.severity.WARN] = visibility_state.warnings_hidden ~= false,
}
local diagnostic_signs_visible = visibility_state.signs_visible ~= false

local function save_visibility_state()
    local ok, encoded = pcall(vim.json.encode, {
        errors_hidden = hidden_severities[vim.diagnostic.severity.ERROR] == true,
        warnings_hidden = hidden_severities[vim.diagnostic.severity.WARN] == true,
        signs_visible = diagnostic_signs_visible,
    })
    if not ok then
        vim.notify("Could not encode diagnostic visibility settings.", vim.log.levels.ERROR)
        return false
    end
    vim.fn.mkdir(vim.fs.dirname(visibility_state_path), "p")
    if vim.fn.writefile({ encoded }, visibility_state_path) ~= 0 then
        vim.notify("Could not save diagnostic visibility settings.", vim.log.levels.ERROR)
        return false
    end
    return true
end

vim.diagnostic.config({
    signs = diagnostic_signs_visible and diagnostic_signs or false,
    underline = true,
    virtual_text = false,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
        header = "Diagnostics",
        prefix = "",
    },
})

-- Keep one sign per line across all diagnostic namespaces. Neovim's default
-- handler otherwise places a sign for every source and diagnostic.
local original_signs_handler = vim.diagnostic.handlers.signs
local aggregate_sign_namespace = vim.api.nvim_create_namespace("config/diagnostic_signs")
local last_sign_opts = {}
local pending_sign_refresh = {}

local function show_diagnostic_signs(bufnr, opts)
    local worst_by_line = {}
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
        local current = worst_by_line[diagnostic.lnum]
        if not current or diagnostic.severity < current.severity then
            worst_by_line[diagnostic.lnum] = diagnostic
        end
    end

    -- Clear every source namespace first, then place the selected signs under
    -- one stable namespace. This prevents native and aggregate signs stacking.
    for namespace in pairs(vim.diagnostic.get_namespaces()) do
        original_signs_handler.hide(namespace, bufnr)
    end
    original_signs_handler.hide(aggregate_sign_namespace, bufnr)
    original_signs_handler.show(
        aggregate_sign_namespace,
        bufnr,
        vim.tbl_values(worst_by_line),
        opts or vim.diagnostic.config()
    )
end

vim.diagnostic.handlers.signs = {
    show = function(_, bufnr, _, opts)
        last_sign_opts[bufnr] = opts
        show_diagnostic_signs(bufnr, opts)
    end,
    hide = function(_, bufnr)
        if not diagnostic_signs_visible then
            for namespace in pairs(vim.diagnostic.get_namespaces()) do
                original_signs_handler.hide(namespace, bufnr)
            end
            original_signs_handler.hide(aggregate_sign_namespace, bufnr)
            return
        end

        -- A hide from one diagnostic namespace can be part of that source's
        -- normal refresh. Defer the aggregate redraw so we keep other sources'
        -- signs visible and let the updated diagnostic set settle first.
        if pending_sign_refresh[bufnr] then
            return
        end
        pending_sign_refresh[bufnr] = true
        vim.schedule(function()
            pending_sign_refresh[bufnr] = nil
            if vim.api.nvim_buf_is_valid(bufnr) and diagnostic_signs_visible then
                show_diagnostic_signs(bufnr, last_sign_opts[bufnr])
            else
                original_signs_handler.hide(aggregate_sign_namespace, bufnr)
            end
        end)
    end,
}

local state_path = vim.fs.joinpath(vim.fn.stdpath("state"), "diagnostic-ignores.json")
local ignored_rules = {}
local diagnostic_signs_config = vim.deepcopy(diagnostic_signs)
local cached_publications = {}
local in_reapply = false

local function normalize_path(path)
    path = vim.fs.normalize(path or "")
    path = path:gsub("\\", "/")
    return vim.fn.has("win32") == 1 and path:lower() or path
end

local function project_root(path)
    local markers = {
        ".git",
        "pyproject.toml",
        "ruff.toml",
        ".ruff.toml",
        "package.json",
        "tsconfig.json",
        "Cargo.toml",
        "go.mod",
        "CMakeLists.txt",
        "Makefile",
    }
    local root = path ~= "" and vim.fs.root(path, markers) or nil
    return normalize_path(root or (path ~= "" and vim.fs.dirname(path)) or vim.fn.getcwd())
end

local function read_ignored_rules()
    if vim.fn.filereadable(state_path) ~= 1 then
        return {}
    end
    local lines = vim.fn.readfile(state_path)
    if #lines == 0 then
        return {}
    end

    local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if ok and type(decoded) == "table" then
        return decoded
    end

    vim.notify("Could not read diagnostic ignore list; starting with an empty list.", vim.log.levels.WARN)
    return {}
end

ignored_rules = read_ignored_rules()

local function save_ignored_rules()
    vim.fn.mkdir(vim.fs.dirname(state_path), "p")
    local ok, result = pcall(vim.fn.writefile, { vim.json.encode(ignored_rules) }, state_path)
    if not ok or result ~= 0 then
        vim.notify("Could not save diagnostic ignore list: " .. tostring(result), vim.log.levels.ERROR)
        return false
    end
    return true
end

local function diagnostic_source(diagnostic, client_id)
    if diagnostic.source and diagnostic.source ~= "" then
        return tostring(diagnostic.source)
    end
    local client = client_id and vim.lsp.get_client_by_id(client_id)
    return client and client.name or "unknown source"
end

local function diagnostic_code(diagnostic)
    if diagnostic.code ~= nil then
        return tostring(diagnostic.code)
    end
    return nil
end

local function ide_standard_severity(diagnostic)
    if diagnostic.severity ~= vim.diagnostic.severity.ERROR then
        return diagnostic.severity
    end

    local code = diagnostic.code
    if type(code) == "table" then
        code = code.value or code.code
    end
    code = tostring(code or ""):lower()
    local message = tostring(diagnostic.message or ""):lower()

    -- Unused declarations are useful cleanup feedback, not blockers. Keep
    -- actual type, syntax, and runtime-related errors at error severity.
    local is_unused_rule = code:find("6133", 1, true)
        or code:find("6192", 1, true)
        or code:find("6196", 1, true)
        or code:find("no-unused-vars", 1, true)
        or code:find("reportunused", 1, true)
        or code:find("unused-local", 1, true)
        or code:find("unused-variable", 1, true)
        or message:find("never used", 1, true)
        or message:find("never read", 1, true)
        or message:find("not accessed", 1, true)
        or message:find("is not used", 1, true)
        or message:find("unused variable", 1, true)
        or message:find("unused import", 1, true)
        or message:find("unused local", 1, true)

    return is_unused_rule and vim.diagnostic.severity.WARN or diagnostic.severity
end

local function allowed_in_quiet_python_profile(diagnostic, source, root)
    if not source:lower():find("pyright", 1, true) then
        return true
    end

    local ok, python = pcall(require, "config.python")
    if not ok then
        return true
    end
    local profile = python.diagnostics_profile(root)
    if profile ~= "quiet" then
        return true
    end

    local code = diagnostic.code
    if type(code) == "table" then
        code = code.value or code.code
    end
    code = tostring(code or ""):lower()
    local message = tostring(diagnostic.message or ""):lower()

    -- Quiet intentionally keeps only core correctness blockers. Match exact
    -- rule names: reportPossiblyUnboundVariable is a heuristic and must not
    -- pass through as reportUnboundVariable.
    local core_rules = {
        reportundefinedvariable = true,
        reportunboundvariable = true,
        reportmissingimports = true,
        reportmissingmodulesource = true,
    }
    return core_rules[code] == true
        or message:find("syntax error", 1, true) ~= nil
        or message:find("invalid syntax", 1, true) ~= nil
end

local function rule_label(rule)
    local code = rule.code or ("message: " .. tostring(rule.message or "(no rule code)"))
    local scope = rule.project == "*" and "all projects" or tostring(rule.project or "unknown project")
    return ("%s · %s · %s"):format(tostring(rule.source or "unknown source"), code, scope)
end

local function matches_rule(diagnostic, source, root)
    local code = diagnostic_code(diagnostic)
    for _, rule in ipairs(ignored_rules) do
        local same_scope = rule.project == "*" or rule.project == root
        local same_rule = rule.source == source
            and ((rule.code and code == rule.code)
                or (not rule.code and rule.message == diagnostic.message))
        if same_scope and same_rule then
            return true
        end
    end
    return false
end

local function should_hide(diagnostic, source, root)
    if hidden_severities[diagnostic.severity] then
        return true
    end
    return matches_rule(diagnostic, source, root)
end

local original_publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
local original_pull_diagnostics = vim.lsp.handlers["textDocument/diagnostic"]

local function filtered_diagnostics(diagnostics, client_id, uri)
    local filename = ""
    if type(uri) == "string" then
        local ok, path = pcall(vim.uri_to_fname, uri)
        filename = ok and path or ""
    end
    local root = project_root(filename)
    local filtered = {}

    for _, diagnostic in ipairs(diagnostics or {}) do
        local source = diagnostic_source(diagnostic, client_id)
        local visible = vim.deepcopy(diagnostic)
        visible.severity = ide_standard_severity(visible)
        if allowed_in_quiet_python_profile(visible, source, root) and not should_hide(visible, source, root) then
            if not visible.source or visible.source == "" then
                visible.source = source
            end
            filtered[#filtered + 1] = visible
        end
    end
    return filtered
end

local function filtered_publish_diagnostics(err, result, ctx, config)
    if not result or type(result.diagnostics) ~= "table" then
        return original_publish_diagnostics(err, result, ctx, config)
    end

    local client_id = ctx and ctx.client_id
    if not in_reapply then
        local cache_key = tostring(client_id or "unknown") .. "\0" .. tostring(result.uri or "")
        cached_publications[cache_key] = {
            err = err,
            result = vim.deepcopy(result),
            ctx = ctx and vim.deepcopy(ctx) or ctx,
            config = config,
        }
    end

    local filtered_result = vim.deepcopy(result)
    filtered_result.diagnostics = filtered_diagnostics(result.diagnostics, client_id, result.uri)
    return original_publish_diagnostics(err, filtered_result, ctx, config)
end

vim.lsp.handlers["textDocument/publishDiagnostics"] = filtered_publish_diagnostics

local function filtered_pull_diagnostics(err, result, ctx, config)
    if not result or result.kind ~= "full" or type(result.items) ~= "table" then
        return original_pull_diagnostics(err, result, ctx, config)
    end

    local client_id = ctx and ctx.client_id
    local params = ctx and ctx.params or {}
    local uri = params.textDocument and params.textDocument.uri or ""
    if not in_reapply then
        local cache_key = tostring(client_id or "unknown") .. "\0pull\0" .. tostring(uri)
        cached_publications[cache_key] = {
            method = "pull",
            err = err,
            result = vim.deepcopy(result),
            ctx = ctx and vim.deepcopy(ctx) or ctx,
            config = config,
        }
    end

    local filtered_result = vim.deepcopy(result)
    filtered_result.items = filtered_diagnostics(result.items, client_id, uri)
    for related_uri, related in pairs(filtered_result.relatedDocuments or {}) do
        if related.kind == "full" and type(related.items) == "table" then
            related.items = filtered_diagnostics(related.items, client_id, related_uri)
        end
    end
    return original_pull_diagnostics(err, filtered_result, ctx, config)
end

if original_pull_diagnostics then
    vim.lsp.handlers["textDocument/diagnostic"] = filtered_pull_diagnostics
end

local function reapply_cached_publications()
    in_reapply = true
    for _, publication in pairs(cached_publications) do
        local bufnr = publication.ctx and publication.ctx.bufnr
        local uri = publication.method == "pull"
                and publication.ctx
                and publication.ctx.params
                and publication.ctx.params.textDocument
                and publication.ctx.params.textDocument.uri
            or publication.result.uri
        if not bufnr or vim.api.nvim_buf_is_valid(bufnr) then
            local handler = publication.method == "pull" and filtered_pull_diagnostics
                or filtered_publish_diagnostics
            handler(
                publication.err,
                vim.deepcopy(publication.result),
                publication.ctx,
                publication.config
            )
        end
    end
    in_reapply = false
end

local function select_item(items, opts, on_choice)
    -- Use Telescope when available so choosing diagnostics/rules is searchable
    -- and doesn't depend on a terminal's inputlist rendering.
    local ok, pickers = pcall(require, "telescope.pickers")
    if ok then
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        pickers.new({}, {
            prompt_title = opts.prompt or "Select one",
            finder = finders.new_table({
                results = items,
                entry_maker = function(item)
                    local label = opts.format_item and opts.format_item(item) or tostring(item)
                    return { value = item, display = label, ordinal = label }
                end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    actions.close(prompt_bufnr)
                    on_choice(selection and selection.value or nil)
                end)
                return true
            end,
        }):find()
        return
    end

    vim.ui.select(items, opts, on_choice)
end

local function diagnostic_for_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local diagnostics = vim.diagnostic.get(0, { lnum = cursor[1] - 1 })
    if #diagnostics == 0 then
        vim.notify("No diagnostic on the current line.", vim.log.levels.INFO)
        return
    end

    select_item(diagnostics, {
        prompt = "Choose a diagnostic rule to ignore:",
        format_item = function(diagnostic)
            local code = diagnostic_code(diagnostic) or "no rule code"
            local message = diagnostic.message:gsub("%s+", " ")
            if #message > 56 then
                message = message:sub(1, 53) .. "..."
            end
            return ("%s · %s · %s"):format(diagnostic_source(diagnostic), code, message)
        end,
    }, function(diagnostic)
        if not diagnostic then
            return
        end

        local filename = vim.api.nvim_buf_get_name(0)
        local root = project_root(filename)
        local scopes = {
            { label = "This project", project = root },
            { label = "Every project", project = "*" },
        }

        select_item(scopes, {
            prompt = "Ignore this rule in:",
            format_item = function(scope)
                if scope.project == "*" then
                    return scope.label
                end
                return scope.label .. " · " .. scope.project
            end,
        }, function(scope)
            if not scope then
                return
            end

            local rule = {
                source = diagnostic_source(diagnostic),
                code = diagnostic_code(diagnostic),
                project = scope.project,
            }
            if not rule.code then
                rule.message = diagnostic.message
            end

            for _, existing in ipairs(ignored_rules) do
                if existing.source == rule.source
                    and existing.code == rule.code
                    and existing.message == rule.message
                    and existing.project == rule.project
                then
                    vim.notify("That diagnostic rule is already ignored.", vim.log.levels.INFO)
                    return
                end
            end

            ignored_rules[#ignored_rules + 1] = rule
            if save_ignored_rules() then
                reapply_cached_publications()
                vim.notify("Ignored " .. rule.source .. " · " .. (rule.code or "matching message"))
            end
        end)
    end)
end

function M.ignore_current_rule()
    diagnostic_for_cursor()
end

function M.unignore_rule()
    if #ignored_rules == 0 then
        vim.notify("There are no ignored diagnostic rules.", vim.log.levels.INFO)
        return
    end

    select_item(ignored_rules, {
        prompt = "Choose an ignored rule to restore:",
        format_item = rule_label,
    }, function(rule)
        if not rule then
            return
        end

        for index, existing in ipairs(ignored_rules) do
            if existing == rule then
                table.remove(ignored_rules, index)
                break
            end
        end

        if save_ignored_rules() then
            reapply_cached_publications()
            vim.notify("Restored " .. rule.source .. " · " .. (rule.code or "matching message"))
        end
    end)
end

function M.select_profile(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype == "python" then
        return require("config.python").select_diagnostics_profile(bufnr)
    end

    local filetype = vim.bo[bufnr].filetype
    local guidance = {
        typescript = "TypeScript rules come from tsconfig.json; extra lint rules belong in the project's ESLint config.",
        typescriptreact = "TypeScript rules come from tsconfig.json; extra lint rules belong in the project's ESLint config.",
        javascript = "JavaScript lint rules come from the project's ESLint config.",
        javascriptreact = "JavaScript lint rules come from the project's ESLint config.",
        c = "C diagnostics come from compiler flags; extra analysis rules belong in .clang-tidy or .clangd.",
        cpp = "C++ diagnostics come from compiler flags; extra analysis rules belong in .clang-tidy or .clangd.",
        lua = "Lua diagnostics are configured in the LuaLS settings in your Neovim config.",
    }
    vim.notify(
        guidance[filetype]
            or ("%s diagnostics use this language server's native/project configuration; there is no generic rule profile."):format(filetype),
        vim.log.levels.INFO,
        { title = "Diagnostic rules" }
    )
end

vim.api.nvim_create_user_command("DiagnosticsProfile", function(command)
    local bufnr = vim.api.nvim_get_current_buf()
    if command.args == "" then
        M.select_profile(bufnr)
        return
    end
    if vim.bo[bufnr].filetype == "python" then
        require("config.python").apply_diagnostics_profile_for_buffer(bufnr, command.args:lower())
    else
        M.select_profile(bufnr)
    end
end, {
    nargs = "?",
    complete = function()
        return { "quiet", "basic", "standard", "strict" }
    end,
    desc = "Choose diagnostics profile for this project",
})

function M.toggle_severity(severity, label)
    hidden_severities[severity] = not hidden_severities[severity]
    save_visibility_state()
    reapply_cached_publications()
    vim.notify(label .. (hidden_severities[severity] and " hidden" or " shown"))
end

function M.toggle_signs()
    diagnostic_signs_visible = not diagnostic_signs_visible
    save_visibility_state()
    vim.diagnostic.config({
        signs = diagnostic_signs_visible and diagnostic_signs_config or false,
    })
    vim.notify("Diagnostic signs " .. (diagnostic_signs_visible and "shown" or "hidden"))
end

return M
