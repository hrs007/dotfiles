-- Keep empty-start dashboard routing separate from buffers opened at startup.
-- Neovide may deliver Finder's open-document event shortly after Neovim has
-- entered the UI. Delay the empty-start dashboard so the file gets priority.
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

local function has_open_file_argument()
    for _, argument in ipairs(vim.fn.argv()) do
        if argument ~= "" and argument ~= "-" then
            return true
        end
    end
    return false
end

local function has_unnamed_modified_buffer()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr)
            and vim.api.nvim_buf_is_loaded(bufnr)
            and vim.bo[bufnr].modified
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
        -- In terminal Neovim with file arguments or stdin, don't delay.
        if has_open_file_argument() or vim.g.read_from_stdin or has_named_file_buffer() or has_unnamed_modified_buffer() then
            return
        end

        -- Allow a grace period for Neovide to receive Finder's open-file event
        -- before showing the empty-start dashboard. 1200ms gives slower Macs
        -- (e.g. M1 Air) sufficient time for LaunchServices to deliver the document event.
        local delay = vim.g.neovide and 1200 or 50

        vim.defer_fn(function()
            -- File arguments, stdin, loaded files, or modified buffers should never be covered by the dashboard.
            if has_open_file_argument() or vim.g.read_from_stdin or has_named_file_buffer() or has_unnamed_modified_buffer() then
                return
            end

            -- Respect a dashboard opened manually during the grace period.
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "dashboard" then
                    return
                end
            end

            vim.cmd("Dashboard")
        end, delay)
    end,
    desc = "Show dashboard after Neovide file-open events settle",
})
