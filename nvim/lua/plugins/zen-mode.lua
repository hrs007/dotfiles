return {
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        opts = {
            window = {
                width = 100,
                height = 1,
                backdrop = 0.9,
                options = {
                    number = true,
                    relativenumber = true,
                    cursorline = true,
                    signcolumn = "yes:1",
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    ruler = false,
                    showcmd = false,
                    laststatus = 0,
                },
                twilight = { enabled = false },
            },
        },
        keys = {
            { "<leader>uz", "<Cmd>ZenMode<CR>", desc = "Interface: Toggle focus mode" },
        },
    },
}
