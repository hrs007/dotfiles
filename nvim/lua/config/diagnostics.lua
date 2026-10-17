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

-- Some language servers (notably Roslyn) report unused symbols as ordinary
-- compiler/analyzer diagnostics instead of semantic tokens. Highlight the
-- reported token range directly so unused names are visibly muted in C# too.
local unused_symbol_namespace = vim.api.nvim_create_namespace("config/unused_symbols")
local unused_diagnostic_codes = {
    CS0168 = true, -- declared but never used
    CS0219 = true, -- assigned but never used
    IDE0051 = true, -- private member never used
    IDE1006 = false, -- naming rule, not an unused symbol
}

local function is_unused_symbol_diagnostic(diagnostic)
    local code = diagnostic.code
    if type(code) == "table" then
        code = code.value or code.code
    end
    code = tostring(code or ""):upper()
    if unused_diagnostic_codes[code] then
        return true
    end

    local message = tostring(diagnostic.message or ""):lower()
    return message:find("never used", 1, true) ~= nil
        or message:find("never read", 1, true) ~= nil
        or message:find("unused variable", 1, true) ~= nil
        or message:find("unused local", 1, true) ~= nil
        or message:find("unused parameter", 1, true) ~= nil
        or message:find("unused member", 1, true) ~= nil
        or message:find("assigned but its value is never used", 1, true) ~= nil
        or message:find("declared but its value is never read", 1, true) ~= nil
end

unused_diagnostic_codes.IDE0052 = true -- private member assigned but never used
unused_diagnostic_codes.IDE0060 = true -- unused parameter
unused_diagnostic_codes.CA1811 = true -- uncalled private code

local unused_diagnostics_by_buffer = {}
local unused_render_pending = {}

local function diagnostic_range(diagnostic)
    if diagnostic.lnum ~= nil then
        return diagnostic.lnum, diagnostic.col or 0,
            diagnostic.end_lnum or diagnostic.lnum, diagnostic.end_col or ((diagnostic.col or 0) + 1)
    end
    local range = diagnostic.range
    if range and range.start and range["end"] then
        return range.start.line, range.start.character,
            range["end"].line, range["end"].character
    end
end

local function is_static_declaration_diagnostic(bufnr, diagnostic)
    if vim.bo[bufnr].filetype ~= "cs" then return false end
    local row, col, end_row, end_col = diagnostic_range(diagnostic)
    if type(row) ~= "number" or row ~= end_row then return false end
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local modifiers, name = line:match("^%s*(.-)%f[%w]class%s+([_%a][_%w]*)")
    if not name then
        modifiers, name = line:match("^%s*(.-)([_%a][_%w]*)%s*%(")
    end
    if not name or not modifiers:match("%f[%w]static%f[%W]") then return false end
    local name_col = (line:find(name, 1, true) or 1) - 1
    local diagnostic_end = end_col or (col + 1)
    local message_names_symbol = tostring(diagnostic.message or ""):lower():find(name:lower(), 1, true) ~= nil
    return message_names_symbol or (col <= name_col and diagnostic_end >= name_col + #name)
end

local function is_xaml_referenced_csharp_method(bufnr, diagnostic)
    if vim.bo[bufnr].filetype ~= "cs" then return false end
    local filename = vim.api.nvim_buf_get_name(bufnr):lower()
    if not filename:match("%.xaml%.cs$") then return false end

    local code = diagnostic.code
    if type(code) == "table" then code = code.value or code.code end
    code = tostring(code or ""):upper()
    local message = tostring(diagnostic.message or ""):lower()
    if code ~= "IDE0051" and code ~= "CA1811"
        and not message:find("private member", 1, true)
        and not message:find("uncalled private code", 1, true)
    then
        return false
    end

    local row = diagnostic_range(diagnostic)
    if type(row) ~= "number" then return false end
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local _, name = line:match("^%s*(.-)([_%a][_%w]*)%s*%(")
    if not name then return false end

    local ok, csharp_unused = pcall(require, "config.csharp_unused")
    return ok and csharp_unused.has_paired_xaml_reference(bufnr, name) or false
end

local function queue_unused_symbol_highlights(bufnr, key, diagnostics)
    if not bufnr or bufnr == 0 then return end
    if vim.bo[bufnr].filetype == "xml" or vim.bo[bufnr].filetype == "xaml" then
        vim.api.nvim_buf_clear_namespace(bufnr, unused_symbol_namespace, 0, -1)
        return
    end
    local by_key = unused_diagnostics_by_buffer[bufnr] or {}
    unused_diagnostics_by_buffer[bufnr] = by_key
    by_key[key] = vim.deepcopy(diagnostics or {})
    if unused_render_pending[bufnr] then return end
    unused_render_pending[bufnr] = true
    vim.schedule(function()
        unused_render_pending[bufnr] = nil
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        vim.api.nvim_buf_clear_namespace(bufnr, unused_symbol_namespace, 0, -1)
        for _, source_diagnostics in pairs(unused_diagnostics_by_buffer[bufnr] or {}) do
            for _, diagnostic in ipairs(source_diagnostics) do
                if is_unused_symbol_diagnostic(diagnostic)
                    and not is_static_declaration_diagnostic(bufnr, diagnostic)
                    and not is_xaml_referenced_csharp_method(bufnr, diagnostic) then
                    local row, col, end_row, end_col = diagnostic_range(diagnostic)
                    if type(row) == "number" and type(col) == "number" then
                        local message = tostring(diagnostic.message or "")
                        local symbol = message:match("['\"]([^'\"]+)['\"]")
                        if symbol and end_row == row then
                            local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
                            local from = math.max(1, col + 1)
                            local found = line:find(symbol, from, true) or line:find(symbol, 1, true)
                            if found then
                                col, end_col = found - 1, found - 1 + #symbol
                            end
                        end
                        end_row = end_row or row
                        end_col = end_col or (col + 1)
                        if end_row == row and end_col <= col then end_col = col + 1 end
                        pcall(vim.api.nvim_buf_set_extmark, bufnr, unused_symbol_namespace, row, col, {
                            end_row = end_row,
                            end_col = end_col,
                            hl_group = "ConfigUnusedSymbol",
                            priority = 250,
                            strict = false,
                        })
                    end
                end
            end
        end
    end)
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = vim.api.nvim_create_augroup("config.unused_symbol_highlights", { clear = true }),
    callback = function(event)
        local bufnr = event.buf
        vim.api.nvim_buf_clear_namespace(bufnr, unused_symbol_namespace, 0, -1)
        if vim.bo[bufnr].filetype == "xml" or vim.bo[bufnr].filetype == "xaml" then return end
        local diagnostics = event.data and event.data.diagnostics or vim.diagnostic.get(bufnr)
        for _, diagnostic in ipairs(diagnostics) do
            local start_row = diagnostic.lnum
            local start_col = diagnostic.col
            local end_row = diagnostic.end_lnum or start_row
            local end_col = diagnostic.end_col
            if is_unused_symbol_diagnostic(diagnostic)
                and not is_static_declaration_diagnostic(bufnr, diagnostic)
                and not is_xaml_referenced_csharp_method(bufnr, diagnostic)
                and type(start_row) == "number"
                and type(start_col) == "number"
                and type(end_col) == "number"
            then
                if end_row == start_row and end_col <= start_col then
                    end_col = start_col + 1
                end
                pcall(vim.api.nvim_buf_set_extmark, bufnr, unused_symbol_namespace, start_row, start_col, {
                    end_row = end_row,
                    end_col = end_col,
                    hl_group = "ConfigUnusedSymbol",
                    priority = 150,
                    strict = false,
                })
            end
        end
    end,
    desc = "Mute symbol ranges reported as unused by language servers",
})

local state_path = vim.fs.joinpath(vim.fn.stdpath("state"), "diagnostic-ignores.json")
local ignored_rules = {}
local diagnostic_signs_config = vim.deepcopy(diagnostic_signs)
local cached_publications = {}
local in_reapply = false
local roslyn_raw_diagnostics = {}

local function normalize_path(path)
    path = vim.fs.normalize(path or "")
    path = path:gsub("\\", "/")
    return vim.fn.has("win32") == 1 and path:lower() or path
end

local function project_root(path)
    if path:lower():match("%.cs$") then
        local ok, project = pcall(require, "config.project")
        if ok then
            local solution = project.find_solution(vim.fs.dirname(path))
            if solution then
                return normalize_path(vim.fs.dirname(solution))
            end
        end
    end
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
        ".editorconfig",
        ".slnx",
        ".sln",
        ".csproj",
        "Directory.Build.props",
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

local function allowed_in_quiet_csharp_profile(diagnostic, filename, root)
    if not filename:lower():match("%.cs$") then
        return true
    end

    local ok, csharp = pcall(require, "config.csharp_diagnostics")
    if not ok or csharp.profile_for_root(root) ~= "quiet" then
        return true
    end

    local code = diagnostic.code
    if type(code) == "table" then
        code = code.value or code.code
    end
    code = tostring(code or ""):upper()
    -- Keep compiler errors even when Roslyn omits the code, plus compiler
    -- warnings (for example CS0168 for an unused catch variable). Hide analyzer
    -- findings, which generally use CA/IDE/SARIF codes instead.
    return (diagnostic.severity == vim.diagnostic.severity.ERROR and code == "")
        or code:match("^CS%d+$") ~= nil
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

local function should_hide(diagnostic, source, root, filename)
    if filename:lower():match("%.cs$") then
        local code = diagnostic.code
        if type(code) == "table" then
            code = code.value or code.code
        end
        if tostring(code or ""):upper():match("^CS%d+$") then
            -- Compiler diagnostics are core feedback, not profile-controlled
            -- analyzer noise. Do not let global toggles or ignored analyzer
            -- rules hide them.
            return false
        end
    end

    if hidden_severities[diagnostic.severity] then
        if filename:lower():match("%.cs$") then
            local ok, csharp = pcall(require, "config.csharp_diagnostics")
            if ok then
                local profile = csharp.profile_for_root(root)
                local code = diagnostic.code
                if type(code) == "table" then
                    code = code.value or code.code
                end
                code = tostring(code or ""):upper()
                local core_compiler_finding = code:match("^CS%d+$") ~= nil
                    or (diagnostic.severity == vim.diagnostic.severity.ERROR and code == "")
                if profile == "quiet" and core_compiler_finding then
                    return matches_rule(diagnostic, source, root)
                elseif profile == "strict" then
                    return matches_rule(diagnostic, source, root)
                end
            end
        end
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
    local ok_buf, bufnr = pcall(vim.uri_to_bufnr, uri)
    if ok_buf and bufnr then
        local cache_key = tostring(client_id or "unknown") .. "\0" .. tostring(uri)
        queue_unused_symbol_highlights(bufnr, cache_key, diagnostics)
    end
    local filtered = {}

    for _, diagnostic in ipairs(diagnostics or {}) do
        local source = diagnostic_source(diagnostic, client_id)
        local visible = vim.deepcopy(diagnostic)
        visible.severity = ide_standard_severity(visible)
        if allowed_in_quiet_python_profile(visible, source, root)
            and allowed_in_quiet_csharp_profile(visible, filename, root)
            and not should_hide(visible, source, root, filename)
        then
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
    if client_id then
        local raw_key = tostring(client_id) .. "\0" .. tostring(result.uri or "")
        roslyn_raw_diagnostics[raw_key] = vim.deepcopy(result.diagnostics)
    end
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
    if client_id then
        local raw_key = tostring(client_id) .. "\0" .. tostring(uri)
        roslyn_raw_diagnostics[raw_key] = vim.deepcopy(result.items)
    end
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

local function refresh_roslyn_diagnostics(bufnr)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if client.name:lower():find("roslyn", 1, true) then
            local params = {
                textDocument = vim.lsp.util.make_text_document_params(bufnr),
            }
            pcall(client.request, client, "textDocument/diagnostic", params, nil, bufnr)
        end
    end
end

-- Roslyn's diagnostics can become stale while editing. Debounce a fresh pull
-- during edits, and also refresh on attach and when leaving insert mode.
local roslyn_refresh_group = vim.api.nvim_create_augroup("config.roslyn_diagnostics", { clear = true })
local refresh_timers = {}
local function queue_roslyn_refresh(bufnr, delay)
    if refresh_timers[bufnr] then
        refresh_timers[bufnr]:stop()
        refresh_timers[bufnr]:close()
    end
    refresh_timers[bufnr] = vim.defer_fn(function()
        refresh_timers[bufnr] = nil
        if vim.api.nvim_buf_is_valid(bufnr) then
            refresh_roslyn_diagnostics(bufnr)
        end
    end, delay)
end

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = roslyn_refresh_group,
    callback = function(event)
        if vim.bo[event.buf].filetype == "cs" then
            queue_roslyn_refresh(event.buf, event.event == "InsertLeave" and 0 or 350)
        end
    end,
    desc = "Refresh Roslyn diagnostics after C# edits",
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = roslyn_refresh_group,
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name:lower():find("roslyn", 1, true) then
            queue_roslyn_refresh(event.buf, 100)
        end
    end,
    desc = "Request diagnostics when Roslyn attaches",
})

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

function M.refresh_cached_publications()
    reapply_cached_publications()
end

function M.refresh_roslyn(bufnr)
    refresh_roslyn_diagnostics(bufnr)
end

local function select_item(items, opts, on_choice)
    -- Share the numbered Telescope picker used by other selection prompts.
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
    local attached_clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(attached_clients) do
        if client.name:lower():find("roslyn", 1, true) then
            return require("config.csharp_diagnostics").select_profile(bufnr)
        end
    end
    local buffer_name = vim.api.nvim_buf_get_name(bufnr)
    if buffer_name:lower():match("%.cs$") then
        return require("config.csharp_diagnostics").select_profile(bufnr)
    end
    if vim.bo[bufnr].filetype == "python" then
        return require("config.python").select_diagnostics_profile(bufnr)
    end
    if vim.bo[bufnr].filetype == "cs" then
        return require("config.csharp_diagnostics").select_profile(bufnr)
    end
    if vim.bo[bufnr].filetype == "oil" then
        local ok, directory = pcall(function()
            return require("oil").get_current_dir()
        end)
        if ok and directory and require("config.project").find_csproj(directory) then
            return require("config.csharp_diagnostics").select_profile_for_path(directory, bufnr)
        end
    end

    local filetype = vim.bo[bufnr].filetype
    local guidance = {
        typescript = "TypeScript rules come from tsconfig.json; extra lint rules belong in the project's ESLint config.",
        typescriptreact = "TypeScript rules come from tsconfig.json; extra lint rules belong in the project's ESLint config.",
        javascript = "JavaScript lint rules come from the project's ESLint config.",
        javascriptreact = "JavaScript lint rules come from the project's ESLint config.",
        cs = "Choose a C# diagnostics profile; it is saved in the project's .editorconfig and applied by Roslyn and the build.",
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

function M.csharp_status(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients, names = vim.lsp.get_clients({ bufnr = bufnr }), {}
    for _, client in ipairs(clients) do
        if client.name:lower():find("roslyn", 1, true) then
            names[#names + 1] = client.name .. " (" .. tostring(client.id) .. ")"
        end
    end
    local diagnostics = vim.diagnostic.get(bufnr)
    local uri = vim.uri_from_bufnr(bufnr)
    local raw_by_client = {}
    for _, client in ipairs(clients) do
        if client.name:lower():find("roslyn", 1, true) then
            local key = tostring(client.id) .. "\0" .. uri
            raw_by_client[#raw_by_client + 1] = {
                name = client.name .. " (" .. tostring(client.id) .. ")",
                items = roslyn_raw_diagnostics[key] or {},
            }
        end
    end
    local codes = {}
    for _, diagnostic in ipairs(diagnostics) do
        local code = diagnostic.code
        if type(code) == "table" then
            code = code.value or code.code
        end
        codes[#codes + 1] = tostring(code or "?") .. ": " .. diagnostic.message:gsub("%s+", " ")
    end
    local catch_location
    for line_number, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        if line:find("Excption", 1, true) then
            catch_location = ("line %d: %s"):format(line_number, vim.trim(line))
            break
        end
    end
    local raw_codes = {}
    for _, publication in ipairs(raw_by_client) do
        for _, diagnostic in ipairs(publication.items) do
            local code = diagnostic.code
            if type(code) == "table" then code = code.value or code.code end
            code = tostring(code or "?")
            local source = tostring(diagnostic.source or "")
            raw_codes[#raw_codes + 1] = ("%s %s: %s"):format(
                code, source, tostring(diagnostic.message or ""):gsub("%s+", " ")
            )
        end
    end
    vim.notify(
        ("Buffer: %s\nFiletype: %s\nModified: %s\nRoslyn: %s\nVisible diagnostics: %d\n%s\n%s"):format(
            vim.api.nvim_buf_get_name(bufnr),
            vim.bo[bufnr].filetype,
            tostring(vim.bo[bufnr].modified),
            #names > 0 and table.concat(names, ", ") or "not attached",
            #diagnostics,
            catch_location or "No 'Excption' text in the current buffer",
            #codes > 0 and table.concat(codes, "\n") or "No diagnostics currently published"
        ),
        vim.log.levels.INFO,
        { title = "C# diagnostic status" }
    )

    vim.notify(
        ("Roslyn published diagnostics: %d\n%s"):format(
            #raw_codes,
            #raw_codes > 0 and table.concat(raw_codes, "\n") or "No Roslyn diagnostics captured yet; edit the buffer, then check again."
        ),
        vim.log.levels.INFO,
        { title = "C# raw Roslyn diagnostics" }
    )
end

vim.api.nvim_create_user_command("CSharpDiagnosticsStatus", function()
    M.csharp_status()
end, { desc = "Show C# LSP attachment and diagnostics for the current buffer" })

vim.api.nvim_create_user_command("DiagnosticsProfile", function(command)
    local bufnr = vim.api.nvim_get_current_buf()
    if command.args == "" then
        M.select_profile(bufnr)
        return
    end
    if vim.bo[bufnr].filetype == "python" then
        require("config.python").apply_diagnostics_profile_for_buffer(bufnr, command.args:lower())
    elseif vim.bo[bufnr].filetype == "cs" then
        require("config.csharp_diagnostics").apply_profile_for_buffer(bufnr, command.args:lower())
    elseif vim.bo[bufnr].filetype == "oil" then
        local ok, directory = pcall(function()
            return require("oil").get_current_dir()
        end)
        if ok and directory and require("config.project").find_csproj(directory) then
            require("config.csharp_diagnostics").apply_profile_for_path(directory, command.args:lower(), bufnr)
        else
            M.select_profile(bufnr)
        end
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
