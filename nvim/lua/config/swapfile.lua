local M = {}

function M.setup()
    pcall(vim.api.nvim_clear_autocmds, {
        group = "nvim.swapfile",
        event = "SwapExists",
    })

    local group = vim.api.nvim_create_augroup("config.swapfile_prompt", { clear = true })
    vim.api.nvim_create_autocmd("SwapExists", {
        group = group,
        callback = function(event)
            local filename = vim.api.nvim_buf_get_name(event.buf)
            local answer = vim.fn.confirm(
                "A swap file exists for:\n" .. (filename ~= "" and filename or "[No Name]"),
                "&Read-only\n&Edit\n&Recover\n&Delete swap\n&Quit",
                3
            )
            vim.v.swapchoice = ({ "o", "e", "r", "d", "q" })[answer] or "q"
        end,
        desc = "Show an interactive swap-file choice prompt",
    })
end

return M
