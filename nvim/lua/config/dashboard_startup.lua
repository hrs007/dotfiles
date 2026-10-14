-- Neovide may deliver Finder's open-document event shortly after Neovim has
-- entered the UI. Delay the empty-start dashboard so the file gets priority.
local startup_group = vim.api.nvim_create_augroup("DashboardStartup", { clear = true })

local function has_named_file_buffer()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr)
            and vim.api.nvim_buf_is_loaded(bufnr)
            and vim.api.nvim_buf_get_name(bufnr) ~= ""
            and vim.bo[bufnr].buftype == ""
            and vim.bo[bufnr].filetype ~= "dashboard"
        then
            return true
        end
    end

    return false
end

local function has_open_file_argument()
    for _, argument in ipairs(vim.fn.argv()) do
        if argument ~= "" and argument ~= "-" then
            return true
        end
    end
    return false
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = startup_group,
    once = true,
    callback = function()
        vim.defer_fn(function()
            -- File arguments and stdin should never be covered by the dashboard.
            if has_open_file_argument() or vim.g.read_from_stdin or has_named_file_buffer() then
                return
            end

            -- Respect a dashboard opened manually during the grace period.
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "dashboard" then
                    return
                end
            end

            vim.cmd("Dashboard")
        end, 1200)
    end,
    desc = "Show dashboard after Neovide file-open events settle",
})
