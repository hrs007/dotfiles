-- Debounced saves for web source files, so dev servers can reload edits after
-- a short pause without writing on every keystroke.
local delay_ms = 1000
local web_filetypes = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    html = true,
    css = true,
    scss = true,
    json = true,
    jsonc = true,
}

local timers = {}
local group = vim.api.nvim_create_augroup("config.web_autosave", { clear = true })

local function eligible(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr)
        and vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].buftype == ""
        and vim.bo[bufnr].modifiable
        and not vim.bo[bufnr].readonly
        and vim.api.nvim_buf_get_name(bufnr) ~= ""
        and web_filetypes[vim.bo[bufnr].filetype] == true
end

local function cancel(bufnr)
    local timer = timers[bufnr]
    if timer then
        timers[bufnr] = nil
        timer:stop()
        timer:close()
    end
end

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(event)
        local bufnr = event.buf
        if not eligible(bufnr) or not vim.bo[bufnr].modified then return end

        cancel(bufnr)
        local timer = vim.uv.new_timer()
        timers[bufnr] = timer
        timer:start(delay_ms, 0, vim.schedule_wrap(function()
            if timers[bufnr] ~= timer then return end
            timers[bufnr] = nil
            timer:close()

            if eligible(bufnr) and vim.bo[bufnr].modified then
                vim.api.nvim_buf_call(bufnr, function()
                    vim.cmd("silent update")
                end)
            end
        end))
    end,
    desc = "Auto-save web files after a short pause",
})

vim.api.nvim_create_autocmd({ "BufWritePre", "BufWipeout" }, {
    group = group,
    callback = function(event) cancel(event.buf) end,
    desc = "Cancel pending web auto-save",
})

return {}
