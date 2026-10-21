return {
    {
        "rmagatti/auto-session",
        lazy = false,
        opts = {
            auto_save = true,
            -- Reopen the saved workspace when Neovim starts in its directory.
            -- Keep auto_restore_last_session disabled so unrelated launches
            -- (for example from home) do not jump to another project.
            auto_restore = true,
            auto_restore_last_session = false,
            session_lens = {},
            bypass_save_filetypes = { "dashboard" },
            -- Do not write stale references for files removed outside Neovim.
            -- Modified, unnamed buffers are retained so unsaved new work is safe.
            pre_save_cmds = {
                function()
                    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                        local name = vim.api.nvim_buf_get_name(bufnr)
                        if name ~= ""
                            and vim.bo[bufnr].buftype == ""
                            and not vim.bo[bufnr].modified
                            and vim.uv.fs_stat(name) == nil
                        then
                            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
                        end
                    end
                    return true
                end,
            },
        },
        keys = {
            { "<leader>ss", "<Cmd>AutoSession save<CR>", desc = "Session: Save" },
            { "<leader>sr", "<Cmd>AutoSession restore<CR>", desc = "Session: Restore" },
            { "<leader>sf", "<Cmd>AutoSession search<CR>", desc = "Session: Find" },
        },
    },
}
