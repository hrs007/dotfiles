-- Show LSP reference counts above Python function, class, and module-level
-- variable declarations. Counts exclude the declaration itself.
local M = {}
local api = vim.api
local namespace = api.nvim_create_namespace("config/python_symbol_references")
local pending = {}
local scan_id = {}

local function declarations_from_lines(bufnr)
    local found = {}
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local function scope_end(start_row, indent)
        local last = start_row
        for index = start_row + 1, #lines do
            local line = lines[index]
            local leading = #(line:match("^(%s*)") or "")
            if line:match("%S") and leading <= indent then break end
            if line:match("%S") then last = index end
        end
        return last - 1, #(lines[last] or "")
    end

    for row, line in ipairs(lines) do
        local indent, name = line:match("^(%s*)def%s+([%a_][%w_]*)%s*%(")
        if not name then indent, name = line:match("^(%s*)async%s+def%s+([%a_][%w_]*)%s*%(") end
        if not name then indent, name = line:match("^(%s*)class%s+([%a_][%w_]*)%s*[:%(]") end
        if name then
            local col = (line:find(name, #indent + 1, true) or 1) - 1
            local block = line:match("^%s*def%s+") or line:match("^%s*async%s+def%s+") or line:match("^%s*class%s+")
            local end_row, end_col = row - 1, #line
            if block then end_row, end_col = scope_end(row, #indent) end
            found[#found + 1] = {
                name = name,
                row = row - 1,
                col = col,
                end_row = end_row,
                end_col = end_col,
                highlight = { row = row - 1, col = 0, end_row = end_row, end_col = end_col },
            }
        elseif not line:match("^%s*#") then
            local lhs = line:match("^(%s*)([%a_][%w_]*)%s*:%s*[^=]+=")
                or line:match("^(%s*)([%a_][%w_]*)%s*=[^=]")
            if lhs then
                local indent_text, variable = line:match("^(%s*)([%a_][%w_]*)")
                local scope_is_local = false
                for earlier = row - 1, 1, -1 do
                    local prev = lines[earlier]
                    local prev_indent = #(prev:match("^(%s*)") or "")
                    if prev:match("^%s*(async%s+)?def%s+") and prev_indent < #indent_text then
                        scope_is_local = true
                        break
                    end
                end
                if not scope_is_local and variable then
                    found[#found + 1] = {
                        name = variable,
                        row = row - 1,
                        col = #indent_text,
                        end_col = #indent_text + #variable,
                        end_row = row - 1,
                        highlight = { row = row - 1, col = 0, end_row = row - 1, end_col = #line },
                    }
                end
            end
        end
    end
    return found
end

local function declarations(bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
    if not ok or not parser then return declarations_from_lines(bufnr) end
    local parsed, trees = pcall(parser.parse, parser)
    if not parsed or not trees or not trees[1] then return declarations_from_lines(bufnr) end
    local root = trees[1]:root()
    local query_ok, query = pcall(vim.treesitter.query.parse, "python", [[
        (function_definition name: (identifier) @symbol)
        (class_definition name: (identifier) @symbol)
        (assignment left: (identifier) @symbol)
        (typed_assignment left: (identifier) @symbol)
    ]])
    if not query_ok then return declarations_from_lines(bufnr) end

    local found, seen = {}, {}
    for _, node in query:iter_captures(root, bufnr, 0, -1) do
        local row, col, end_row, end_col = node:range()
        local parent = node:parent()
        local local_scope = false
        while parent do
            local kind = parent:type()
            if kind == "function_definition" or kind == "lambda" then
                local_scope = true
                break
            end
            parent = parent:parent()
        end
        if not local_scope then
            local name = vim.treesitter.get_node_text(node, bufnr)
            local key = row .. ":" .. col
            if name ~= "" and not seen[key] then
                seen[key] = true
                local highlight_node = node
                local parent = node:parent()
                while parent do
                    local kind = parent:type()
                    if kind == "function_definition" or kind == "class_definition" then
                        highlight_node = parent
                        break
                    elseif kind == "assignment" or kind == "typed_assignment" then
                        highlight_node = parent
                        break
                    end
                    parent = parent:parent()
                end
                local highlight_row, highlight_col, highlight_end_row, highlight_end_col = highlight_node:range()
                found[#found + 1] = {
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
                }
            end
        end
    end
    return #found > 0 and found or declarations_from_lines(bufnr)
end

local function scan(bufnr)
    if not api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "python" then return end
    scan_id[bufnr] = (scan_id[bufnr] or 0) + 1
    local current_scan = scan_id[bufnr]
    local symbols = declarations(bufnr)
    if #symbols == 0 then return end

    local client
    for _, attached in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if attached:supports_method("textDocument/references", bufnr) then
            client = attached
            break
        end
    end
    if not client then return end

    local results, remaining = {}, #symbols
    for _, symbol in ipairs(symbols) do
        local line = api.nvim_buf_get_lines(bufnr, symbol.row, symbol.row + 1, false)[1] or ""
        local character = symbol.col
        if vim.str_utfindex then
            local ok, utf16_col = pcall(vim.str_utfindex, line, "utf-16", symbol.col)
            if ok then character = utf16_col end
        end
        local params = {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            position = { line = symbol.row, character = character },
            context = { includeDeclaration = false },
        }
        client:request("textDocument/references", params, function(err, references)
            if not err then results[#results + 1] = { symbol = symbol, count = type(references) == "table" and #references or 0 } end
            remaining = remaining - 1
            if remaining ~= 0 or err then return end
            vim.schedule(function()
                if not api.nvim_buf_is_valid(bufnr) or current_scan ~= scan_id[bufnr] then return end
                api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
                for _, result in ipairs(results) do
                    local item = result.symbol
                    local signature = api.nvim_buf_get_lines(bufnr, item.row, item.row + 1, false)[1] or ""
                    local indentation = signature:match("^(%s*)") or ""
                    local label = result.count == 1 and "1 ref" or (result.count .. " refs")
                    local mark = {
                        virt_lines = { { { indentation .. label, result.count == 0 and "ConfigUnusedSymbol" or "ConfigReferenceCount" } } },
                        virt_lines_above = true,
                        priority = 250,
                    }
                    if result.count == 0 then
                        mark.hl_group = "ConfigUnusedSymbol"
                        local range = item.highlight or {
                            row = item.row,
                            col = item.col,
                            end_row = item.end_row or item.row,
                            end_col = item.end_col or (item.col + #(item.name or "")),
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

function M.setup()
    local group = api.nvim_create_augroup("config.python_symbol_references", { clear = true })
    local function close_timer(timer)
        if not timer then return end
        local ok, closing = pcall(timer.is_closing, timer)
        if ok and not closing then pcall(timer.close, timer) end
    end
    local function schedule(bufnr)
        local previous = pending[bufnr]
        if previous then
            pending[bufnr] = nil
            pcall(previous.stop, previous)
            close_timer(previous)
        end
        local timer = vim.uv.new_timer()
        pending[bufnr] = timer
        timer:start(700, 0, vim.schedule_wrap(function()
            if pending[bufnr] == timer then
                pending[bufnr] = nil
                if api.nvim_buf_is_valid(bufnr) then scan(bufnr) end
            end
            close_timer(timer)
        end))
    end
    api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave", "FocusGained", "LspAttach", "FileType" }, {
        group = group,
        callback = function(event)
            local bufnr = event.buf ~= 0 and event.buf or api.nvim_get_current_buf()
            if api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "python" then schedule(bufnr) end
        end,
        desc = "Refresh Python symbol reference counts",
    })
end

return M
