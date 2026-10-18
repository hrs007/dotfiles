-- Dim document symbols with no references for languages without a dedicated
-- scanner. Uses standard LSP documentSymbol/references requests.
local M = {}
local api = vim.api
local namespace = api.nvim_create_namespace("config/generic_symbol_references")
local pending, scan_id = {}, {}

local symbol_kinds = {
    [5] = true,  -- Class
    [6] = true,  -- Method
    [7] = true,  -- Property
    [8] = true,  -- Field
    [10] = true, -- Enum
    [11] = true, -- Interface
    [12] = true, -- Function
    [13] = true, -- Variable
    [14] = true, -- Constant
    [23] = true, -- Struct
}

local handled_filetypes = {
    xml = true, -- Includes XAML; XML symbols are not reliably reference-counted.
    xaml = true,
    python = true,
    c = true,
    cpp = true,
    cs = true,
    -- TypeScript/JavaScript document symbols can include object-literal
    -- properties (for example `plugins` inside defineConfig). Those are not
    -- declarations whose LSP references can be counted reliably; use the
    -- language server's unused diagnostics/semantic tokens for these files.
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    html = true,
}

local function symbol_location(symbol, uri)
    if symbol.location then
        if symbol.location.uri ~= uri then return nil end
        return symbol.location.range, symbol.location.range, symbol.kind
    end
    -- The selection range is the identifier used to ask for references. The
    -- enclosing range is the declaration body to dim when it has no uses.
    return symbol.selectionRange or symbol.range, symbol.range or symbol.selectionRange, symbol.kind
end

local function collect_symbols(symbols, uri, output)
    for _, symbol in ipairs(symbols or {}) do
        local position_range, highlight_range, kind = symbol_location(symbol, uri)
        if position_range and position_range.start and highlight_range and highlight_range.start and symbol_kinds[kind] then
            output[#output + 1] = {
                name = symbol.name,
                position_range = position_range,
                highlight_range = highlight_range,
            }
        end
        if symbol.children then
            collect_symbols(symbol.children, uri, output)
        end
    end
end

local function byte_column(line, character, encoding)
    if vim.str_byteindex then
        local ok, column = pcall(vim.str_byteindex, line, encoding or "utf-16", character, true)
        if ok then return column end
    end
    return math.min(#line, character)
end

local function scan(bufnr)
    if not api.nvim_buf_is_valid(bufnr)
        or not api.nvim_buf_is_loaded(bufnr)
        or handled_filetypes[vim.bo[bufnr].filetype]
    then
        return
    end

    scan_id[bufnr] = (scan_id[bufnr] or 0) + 1
    local current_scan = scan_id[bufnr]
    local client
    for _, attached in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if attached:supports_method("textDocument/documentSymbol", bufnr)
            and attached:supports_method("textDocument/references", bufnr)
        then
            client = attached
            break
        end
    end

    api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    if not client then return end

    local uri = vim.uri_from_bufnr(bufnr)
    local encoding = client.offset_encoding or "utf-16"
    client:request("textDocument/documentSymbol", {
        textDocument = { uri = uri },
    }, function(err, response)
        if err or type(response) ~= "table" or current_scan ~= scan_id[bufnr] then return end
        local symbols = {}
        collect_symbols(response, uri, symbols)
        if #symbols == 0 then return end

        local results, remaining = {}, #symbols
        for _, symbol in ipairs(symbols) do
            local start = symbol.position_range.start
            local line = api.nvim_buf_get_lines(bufnr, start.line, start.line + 1, false)[1] or ""
            local byte_col = byte_column(line, start.character, encoding)
            client:request("textDocument/references", {
                textDocument = { uri = uri },
                position = { line = start.line, character = start.character },
                context = { includeDeclaration = false },
            }, function(reference_err, references)
                if not reference_err then
                    results[#results + 1] = {
                        symbol = symbol,
                        count = type(references) == "table" and #references or 0,
                        byte_col = byte_col,
                    }
                end
                remaining = remaining - 1
                if remaining ~= 0 or reference_err then return end

                vim.schedule(function()
                    if not api.nvim_buf_is_valid(bufnr) or current_scan ~= scan_id[bufnr] then return end
                    for _, result in ipairs(results) do
                        if result.count == 0 then
                            local range = result.symbol.highlight_range
                            local end_line = api.nvim_buf_get_lines(bufnr, range["end"].line, range["end"].line + 1, false)[1] or ""
                            local end_col = byte_column(end_line, range["end"].character, encoding)
                            if range["end"].line == range.start.line and end_col <= result.byte_col then
                                end_col = result.byte_col + 1
                            end
                            pcall(api.nvim_buf_set_extmark, bufnr, namespace, range.start.line, result.byte_col, {
                                end_row = range["end"].line,
                                end_col = end_col,
                                hl_group = "ConfigUnusedSymbol",
                                priority = 250,
                                strict = false,
                            })
                        end
                    end
                end)
            end)
        end
    end)
end

function M.setup()
    -- Remove marks from any buffers that were scanned before this module was
    -- reloaded with a filetype now excluded from generic reference counting.
    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(bufnr) and handled_filetypes[vim.bo[bufnr].filetype] then
            api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
        end
    end

    local group = api.nvim_create_augroup("config.generic_symbol_references", { clear = true })
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
            if api.nvim_buf_is_valid(bufnr) and not handled_filetypes[vim.bo[bufnr].filetype] then
                schedule(bufnr)
            end
        end,
        desc = "Dim unused symbols from LSP reference results",
    })
end

return M
