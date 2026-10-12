return {
    {
        "rmagatti/auto-session",
        lazy = false,
        opts = {
            auto_save = true,
            auto_restore = true,
            session_lens = {},
            bypass_save_filetypes = { "dashboard" },
        },
        keys = {
            { "<leader>ss", "<Cmd>AutoSession save<CR>", desc = "Session: Save" },
            { "<leader>sr", "<Cmd>AutoSession restore<CR>", desc = "Session: Restore" },
            { "<leader>sf", "<Cmd>AutoSession search<CR>", desc = "Session: Find" },
        },
    },
}
