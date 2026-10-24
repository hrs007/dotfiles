-- Show semantic C# reference counts for declarations in the current file.
local M = {}
local api = vim.api
local namespace = api.nvim_create_namespace("config/csharp_method_references")
local pending = {}
local scan_id = {}

local function collect_declarations_from_lines(bufnr)
    local declarations = {}
    for row, line in ipairs(api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local prefix, name = line:match("^%s*(.-)([_%a][_%w]*)%s*%(")
        local has_access = prefix and (
            prefix:find("private", 1, true)
            or prefix:find("protected", 1, true)
            or prefix:find("public", 1, true)
            or prefix:find("internal", 1, true)
        )
        if has_access and name then
            local col = line:find(name, 1, true) - 1
            declarations[#declarations + 1] = {
                name = name,
                row = row - 1,
                col = col,
                end_row = row - 1,
                end_col = col + #name,
                highlight = { row = row - 1, col = 0, end_row = row - 1, end_col = #line },
                is_static = prefix:match("%f[%w]static%f[%W]") ~= nil,
            }
        end
    end
    return declarations
end

local function collect_declarations(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "c_sharp")
    if not ok then parser = nil end
    if not parser then
        return collect_declarations_from_lines(bufnr)
    end
    local parse_ok, trees = pcall(parser.parse, parser)
    if not parse_ok then return collect_declarations_from_lines(bufnr) end
    local root = trees and trees[1] and trees[1]:root()
    if not root then return {} end

    local query_ok, query = pcall(vim.treesitter.query.parse, "c_sharp", [[
        (method_declaration name: (identifier) @symbol)
        (class_declaration name: (identifier) @symbol)
        (struct_declaration name: (identifier) @symbol)
        (interface_declaration name: (identifier) @symbol)
        (enum_declaration name: (identifier) @symbol)
        (record_declaration name: (identifier) @symbol)
        (field_declaration
            (variable_declaration
                (variable_declarator name: (identifier) @symbol)))
        (event_field_declaration
            (variable_declaration
                (variable_declarator name: (identifier) @symbol)))
        (property_declaration name: (identifier) @symbol)
        (event_declaration name: (identifier) @symbol)
    ]])
    if not query_ok then return collect_declarations_from_lines(bufnr) end

    local declarations, seen = {}, {}
    for _, name_node in query:iter_captures(root, bufnr, 0, -1) do
        local row, col, end_row, end_col = name_node:range()
        local name = vim.treesitter.get_node_text(name_node, bufnr)
        local key = row .. ":" .. col .. ":" .. name
        if not seen[key] then
            seen[key] = true
            local highlight_node = name_node
            local parent = name_node:parent()
            local is_static_declaration = false
            while parent do
                local kind = parent:type()
                if kind == "class_declaration" or kind == "method_declaration" then
                    local declaration_line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
                    local prefix = declaration_line:sub(1, col)
                    is_static_declaration = prefix:match("%f[%w]static%f[%W]") ~= nil
                end
                if kind == "method_declaration" or kind == "class_declaration"
                    or kind == "struct_declaration" or kind == "interface_declaration"
                    or kind == "enum_declaration" or kind == "record_declaration"
                    or kind == "field_declaration" or kind == "event_field_declaration"
                    or kind == "property_declaration" or kind == "event_declaration"
                then
                    highlight_node = parent
                    break
                end
                parent = parent:parent()
            end
            local highlight_row, highlight_col, highlight_end_row, highlight_end_col = highlight_node:range()
            declarations[#declarations + 1] = {
                name = name,
                row = row,
                col = col,
                end_row = end_row,
                end_col = end_col,
                highlight = {
                    row = highlight_row,
                    col = highlight_col,
                    end_row = highlight_end_row,
                    end_col = highlight_end_col,
                },
                is_static = is_static_declaration,
            }
        end
    end
    return #declarations > 0 and declarations or collect_declarations_from_lines(bufnr)
end

local function paired_xaml_references(bufnr, symbol)
    local source_path = api.nvim_buf_get_name(bufnr)
    if not source_path:lower():match("%.xaml%.cs$") then return 0 end
    local xaml_path = source_path:gsub("%.[cC][sS]$", "")
    local expected = vim.fs.normalize(xaml_path):gsub("\\", "/"):lower()
    local lines
    for _, candidate in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(candidate)
            and vim.fs.normalize(api.nvim_buf_get_name(candidate)):gsub("\\", "/"):lower() == expected then
            lines = api.nvim_buf_get_lines(candidate, 0, -1, false)
            break
        end
    end
    if not lines then lines = vim.fn.readfile(xaml_path) end

    local count = 0
    for _, line in ipairs(lines) do
        for attribute, value in line:gmatch("([%w_:%-%.]+)%s*=%s*[\"']([^\"']*)[\"']") do
            -- x:Class names the backing type; it is not a use of a member.
            if attribute:lower() ~= "x:class" then
                for token in value:gmatch("[_%a][_%w]*") do
                    if token == symbol then count = count + 1 end
                end
            end
        end
    end
    return count
end

function M.has_paired_xaml_reference(bufnr, symbol)
    return paired_xaml_references(bufnr, symbol) > 0
end

local function scan(bufnr)
    if not api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "cs" then return end
    scan_id[bufnr] = (scan_id[bufnr] or 0) + 1
    local current_scan = scan_id[bufnr]
    local declarations = collect_declarations(bufnr)
    if #declarations == 0 then return end

    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    local client
    for _, attached in ipairs(clients) do
        if attached.name:lower():find("roslyn", 1, true)
            and attached:supports_method("textDocument/references", bufnr) then
            client = attached
            break
        end
    end
    if not client then return end

    local requested = {}
    local results, remaining = {}, 0
    for _, declaration in ipairs(declarations) do
        local declaration_key = declaration.row .. ":" .. declaration.col
        if not requested[declaration_key] then
            requested[declaration_key] = true
            remaining = remaining + 1
            local line = api.nvim_buf_get_lines(bufnr, declaration.row, declaration.row + 1, false)[1] or ""
            local character = declaration.col
            if vim.str_utfindex then
                local ok, utf16_col = pcall(vim.str_utfindex, line, "utf-16", declaration.col)
                if ok then character = utf16_col end
            end
            client:request("textDocument/references", {
                textDocument = { uri = vim.uri_from_bufnr(bufnr) },
                position = { line = declaration.row, character = character },
                context = { includeDeclaration = false },
            }, function(err, references)
                if not err then
                    results[declaration_key] = {
                        declaration = declaration,
                        count = (type(references) == "table" and #references or 0)
                            + paired_xaml_references(bufnr, declaration.name),
                    }
                end
                remaining = remaining - 1
                if remaining ~= 0 or err then return end
                vim.schedule(function()
                    if not api.nvim_buf_is_valid(bufnr) or current_scan ~= scan_id[bufnr] then return end
                    api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
                    for _, result in pairs(results) do
                        local item = result.declaration
                        local signature = api.nvim_buf_get_lines(bufnr, item.row, item.row + 1, false)[1] or ""
                        local indentation = signature:match("^(%s*)") or ""
                        local label = result.count == 1 and "1 ref" or string.format("%d refs", result.count)
                        local mark = {
                            virt_lines = { { { indentation .. label, result.count == 0 and "ConfigUnusedSymbol" or "ConfigReferenceCount" } } },
                            virt_lines_above = true,
                            priority = 250,
                        }
                        if result.count == 0 and not item.is_static then
                            mark.hl_group = "ConfigUnusedSymbol"
                            local range = item.highlight or {
                                row = item.row,
                                col = item.col,
                                end_row = item.end_row or item.row,
                                end_col = item.end_col or item.col + #(item.name or ""),
                            }
                            mark.end_row = range.end_row
                            mark.end_col = range.end_col
                            pcall(api.nvim_buf_set_extmark, bufnr, namespace, range.row, range.col, mark)
                        else
                            pcall(api.nvim_buf_set_extmark, bufnr, namespace, item.row, item.col, mark)
                        end
                    end
                end)
            end)
        end
    end
end

function M.setup()
    local group = api.nvim_create_augroup("config.csharp_method_references", { clear = true })
    local function close_timer(timer)
        if not timer then return end
        local ok, closing = pcall(timer.is_closing, timer)
        if ok and not closing then pcall(timer.close, timer) end
    end

    local function schedule_scan(bufnr)
        local previous = pending[bufnr]
        if previous then
            pending[bufnr] = nil
            pcall(previous.stop, previous)
            close_timer(previous)
        end
        local timer = vim.uv.new_timer()
        pending[bufnr] = timer
        timer:start(700, 0, vim.schedule_wrap(function()
            -- A newer edit may have replaced and closed this timer after its
            -- callback was queued. Only the current timer may launch a scan.
            if pending[bufnr] == timer then
                pending[bufnr] = nil
                if api.nvim_buf_is_valid(bufnr) then scan(bufnr) end
            end
            close_timer(timer)
        end))
    end

    local function refresh_buffer(event_buf)
        if event_buf == 0 then event_buf = api.nvim_get_current_buf() end
        if not api.nvim_buf_is_valid(event_buf) then return end
        local filetype = vim.bo[event_buf].filetype
        if filetype == "cs" then
            schedule_scan(event_buf)
            return
        end
        if filetype ~= "xml" and not api.nvim_buf_get_name(event_buf):lower():match("%.xaml$") then return end

        -- XAML references are part of Roslyn's project workspace, but the
        -- reference-count display lives on the paired code-behind buffer.
        local xaml_path = api.nvim_buf_get_name(event_buf)
        if not xaml_path:lower():match("%.xaml$") then return end
        local codebehind_path = (xaml_path:gsub("%.[xX][aA][mM][lL]$", ".xaml.cs")):gsub("\\", "/"):lower()
        for _, candidate in ipairs(api.nvim_list_bufs()) do
            if api.nvim_buf_is_loaded(candidate) and vim.bo[candidate].filetype == "cs" then
                local candidate_path = api.nvim_buf_get_name(candidate):gsub("\\", "/"):lower()
                if candidate_path == codebehind_path then schedule_scan(candidate) end
            end
        end
    end

    api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "LspAttach", "FileType" }, {
        group = group,
        callback = function(event)
            refresh_buffer(event.buf)
        end,
        desc = "Refresh per-method C# reference counts after edits and file changes",
    })
end

return M
