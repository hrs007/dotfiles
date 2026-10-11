return {
    {
        "folke/which-key.nvim",

        event = "VeryLazy",

        opts = {
            delay = 500,

            icons = {
                mappings = true,
                keys = {},
            },

            spec = {
                { "<leader>f", group = "Find" },
                { "<leader>h", group = "Git" },
                { "<leader>d", group = "Diagnostics" },
                { "<leader>l", group = "LSP" },
                { "<leader>c", group = "Code" },
                { "<leader>D", group = "Debug" },
            },

            win = {
                border = "rounded",
            },

            layout = {
                width = { min = 20, max = 50 },
                spacing = 3,
            },
        },
    },
}
