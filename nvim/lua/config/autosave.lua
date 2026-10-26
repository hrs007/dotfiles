-- Debounced saves for web source files, so dev servers can reload edits after
-- a short pause without writing on every keystroke.
local state_path = vim.fs.joinpath(vim.fn.stdpath("state"), "web-autosave.json")
local function load_delay_seconds()
    if vim.fn.filereadable(state_path) == 1 then
        local ok, state = pcall(vim.json.decode, table.concat(vim.fn.readfile(state_path), "\n"))
        if ok and type(state) == "table" and tonumber(state.delay_seconds) then
            return math.max(0, tonumber(state.delay_seconds))
        end
    end
    return math.max(0, tonumber(vim.g.web_autosave_delay_seconds) or 5)
end

local delay_seconds = load_delay_seconds()
local delay_ms = delay_seconds * 1000
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

vim.api.nvim_create_user_command("WebAutosaveDelay", function(command)
    local seconds = tonumber(command.args)
    if not seconds or seconds < 0 then
        vim.notify("Usage: :WebAutosaveDelay {seconds} (use 0 for immediate save)", vim.log.levels.ERROR)
        return
    end

    delay_seconds = seconds
    delay_ms = seconds * 1000
    vim.g.web_autosave_delay_seconds = seconds
    vim.fn.mkdir(vim.fs.dirname(state_path), "p")
    local ok, encoded = pcall(vim.json.encode, { delay_seconds = seconds })
    if not ok or vim.fn.writefile({ encoded }, state_path) ~= 0 then
        vim.notify("Could not save web autosave delay.", vim.log.levels.ERROR)
        return
    end
    vim.notify(("Web autosave delay set to %s seconds."):format(seconds), vim.log.levels.INFO)
end, {
    nargs = 1,
    desc = "Set and persist web-file autosave delay in seconds",
})

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
