-- Inline LSP reference counts for C/C++ symbols outside function-local scope.
local M = {}
local api = vim.api
local namespace = api.nvim_create_namespace("config/c_family_symbol_references")
local pending, scan_id = {}, {}

local function source_declarations(bufnr)
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local candidates, depth = {}, 0
    for row, line in ipairs(lines) do
        local clean = line:gsub("//.*$", "")
        local indent = clean:match("^(%s*)") or ""
        local is_top_level = depth == 0
        local name
        if is_top_level then
            name = clean:match("([%a_][%w_]*)%s*%([^;{}]*%)%s*const%s*[%{]?")
                or clean:match("([%a_][%w_]*)%s*%([^;{}]*%)%s*[%{]")
            if not name then
                name = clean:match("^%s*class%s+([%a_][%w_]*)")
                    or clean:match("^%s*struct%s+([%a_][%w_]*)")
                    or clean:match("^%s*union%s+([%a_][%w_]*)")
                    or clean:match("^%s*enum%s+([%a_][%w_]*)")
            end
            if not name then
                local declarator = clean:match("^%s*[%w_:<>,*&%s]+%s+([%a_][%w_]*)%s*(=[^=].*)?;%s*$")
                if declarator and not clean:match("^%s*#") then name = declarator end
            end
        elseif clean:match("^%s*[%w_:<>,*&%s]+%s+[%*&]?([%a_][%w_]*)%s*(=[^=].*)?;%s*$") then
            -- Class fields are declarations outside a function body. Keep
            -- member declarations while ignoring locals inside function bodies.
            local in_function = false
            for earlier = row - 1, 1, -1 do
                if lines[earlier]:match("[%{]%s*$") then
                    local previous_depth = 0
                    for i = earlier, 1, -1 do
                        previous_depth = previous_depth + select(2, (lines[i]:gsub("%}", "")))
                            - select(2, (lines[i]:gsub("%{", "")))
                        if previous_depth < 0 then break end
                    end
                    in_function = lines[earlier]:match("%)%s*[%{]?") ~= nil
                    break
                end
            end
            if not in_function then
                name = clean:match("[%*&]?([%a_][%w_]*)%s*(=[^=].*)?;%s*$")
            end
        end
        if name then
            local col = (clean:find(name, 1, true) or 1) - 1
            candidates[#candidates + 1] = { name = name, row = row - 1, col = col, indent = #indent }
        end
        local _, opens = clean:gsub("%{", "")
        local _, closes = clean:gsub("%}", "")
        depth = math.max(0, depth + opens - closes)
    end
    return candidates
end

local function declarations(bufnr)
    local language = vim.bo[bufnr].filetype == "c" and "c" or "cpp"
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, language)
    if not ok or not parser then return source_declarations(bufnr) end
    local parsed, trees = pcall(parser.parse, parser)
    if not parsed or not trees or not trees[1] then return source_declarations(bufnr) end
    local query_text = [[
        (function_definition declarator: (function_declarator declarator: (identifier) @symbol))
        (class_specifier name: (type_identifier) @symbol)
        (struct_specifier name: (type_identifier) @symbol)
        (enum_specifier name: (type_identifier) @symbol)
        (declaration (init_declarator declarator: (identifier) @symbol))
        (field_declaration declarator: (field_identifier) @symbol)
    ]]
    local query_ok, query = pcall(vim.treesitter.query.parse, language, query_text)
    if not query_ok then return source_declarations(bufnr) end
    local found, seen = {}, {}
    for _, node in query:iter_captures(trees[1]:root(), bufnr, 0, -1) do
        local row, col, end_row, end_col = node:range()
        local parent, local_scope = node:parent(), false
        while parent do
            local kind = parent:type()
            if kind == "function_definition" or kind == "lambda_expression" then
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
                found[#found + 1] = { name = name, row = row, col = col, end_row = end_row, end_col = end_col }
            end
        end
    end
    return #found > 0 and found or source_declarations(bufnr)
end

local function scan(bufnr)
    if not api.nvim_buf_is_valid(bufnr) then return end
    local ft = vim.bo[bufnr].filetype
    if ft ~= "c" and ft ~= "cpp" then return end
    scan_id[bufnr] = (scan_id[bufnr] or 0) + 1
    local id = scan_id[bufnr]
    local symbols = declarations(bufnr)
    local client
    for _, attached in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if attached:supports_method("textDocument/references", bufnr) then client = attached; break end
    end
    if not client then return end
    local results, remaining = {}, #symbols
    for _, symbol in ipairs(symbols) do
        local line = api.nvim_buf_get_lines(bufnr, symbol.row, symbol.row + 1, false)[1] or ""
        local character = symbol.col
        if vim.str_utfindex then
            local ok, col = pcall(vim.str_utfindex, line, "utf-16", symbol.col)
            if ok then character = col end
        end
        client:request("textDocument/references", {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            position = { line = symbol.row, character = character },
            context = { includeDeclaration = false },
        }, function(err, refs)
            if not err then results[#results + 1] = { symbol = symbol, count = type(refs) == "table" and #refs or 0 } end
            remaining = remaining - 1
            if remaining ~= 0 or err then return end
            vim.schedule(function()
                if not api.nvim_buf_is_valid(bufnr) or scan_id[bufnr] ~= id then return end
                api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
                for _, result in ipairs(results) do
                    local item = result.symbol
                    local text = api.nvim_buf_get_lines(bufnr, item.row, item.row + 1, false)[1] or ""
                    local indentation = text:match("^(%s*)") or ""
                    local label = result.count == 1 and "1 ref" or (result.count .. " refs")
                    local mark = {
                        virt_lines = { { { indentation .. label, result.count == 0 and "ConfigUnusedSymbol" or "ConfigReferenceCount" } } },
                        virt_lines_above = true,
                        priority = 250,
                    }
                    if result.count == 0 then mark.hl_group = "ConfigUnusedSymbol" end
                    pcall(api.nvim_buf_set_extmark, bufnr, namespace, item.row, item.col, mark)
                end
            end)
        end)
    end
end

function M.setup()
    local group = api.nvim_create_augroup("config.c_family_symbol_references", { clear = true })
    local function close_timer(timer)
        if not timer then return end
        local ok, closing = pcall(timer.is_closing, timer)
        if ok and not closing then pcall(timer.close, timer) end
    end
    local function schedule(bufnr)
        local old = pending[bufnr]
        if old then pending[bufnr] = nil; pcall(old.stop, old); close_timer(old) end
        local timer = vim.uv.new_timer()
        pending[bufnr] = timer
        timer:start(700, 0, vim.schedule_wrap(function()
            if pending[bufnr] == timer then pending[bufnr] = nil; scan(bufnr) end
            close_timer(timer)
        end))
    end
    api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave", "FocusGained", "LspAttach", "FileType" }, {
        group = group,
        callback = function(event)
            local bufnr = event.buf ~= 0 and event.buf or api.nvim_get_current_buf()
            local ft = api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype or ""
            if ft == "c" or ft == "cpp" then schedule(bufnr) end
        end,
        desc = "Refresh C/C++ symbol reference counts",
    })
end

return M
