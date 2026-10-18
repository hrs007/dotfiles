-- Keep empty-start dashboard routing separate from buffers opened at startup.
local startup_group = vim.api.nvim_create_augroup("DashboardStartup", { clear = true })

-- Suppress Neovim's built-in welcome screen while the configured dashboard
-- initializes, avoiding two different startup screens in sequence.
vim.opt.shortmess:append("I")

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

vim.api.nvim_create_autocmd("VimEnter", {
    group = startup_group,
    once = true,
    callback = function()
        -- Neovide may deliver OS file-open requests after startup, so Neovim
        -- cannot reliably distinguish them from an empty launch. Leave its
        -- startup buffer alone; `:Dashboard` remains available.
        if vim.g.neovide then
            return
        end

        vim.defer_fn(function()
            -- File arguments and stdin should never be covered by the dashboard.
            if #vim.fn.argv() > 0 or vim.g.read_from_stdin or has_named_file_buffer() then
                return
            end

            -- Respect a dashboard opened manually during the grace period.
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "dashboard" then
                    return
                end
            end

            vim.cmd("Dashboard")
        end, 0)
    end,
    desc = "Show dashboard on empty startup when file-open events are synchronous",
})
