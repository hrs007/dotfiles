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
                { "<leader>g", group = "Git" },
                { "<leader>l", group = "Markup / XAML" },
                { "<leader>h", group = "Git hunks" },
                { "<leader>p", group = "Window management" },
                { "<leader>s", group = "Sessions" },
                { "<leader>d", group = "Diagnostics" },
                { "<leader>c", group = "Code" },
                { "<leader>D", group = "Debug" },
                { "<leader>x", group = "Trouble" },
                { "<leader>v", group = "Buffers" },
                { "<leader>m", group = "WPF" },
                { "<leader>n", group = "Interface" },
                { "<leader>t", group = "Terminal" },
                { "<leader>a", group = "AI" },
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
