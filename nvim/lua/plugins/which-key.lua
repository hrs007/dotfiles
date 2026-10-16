return {
    {
        "folke/which-key.nvim",

        event = "VeryLazy",

        opts = {
            delay = 300,

            icons = {
                mappings = true,
                keys = {},
            },

            spec = {
                { "<leader>e", desc = "Open file explorer", icon = { icon = "󰙅", color = "cyan" } },
                { "<leader>f", group = "Find", icon = { icon = "", color = "green" } },
                { "<leader>g", group = "Git", icon = { icon = "󰊢", color = "orange" } },
                { "<leader>l", group = "Markup / XAML", icon = { icon = "󰅩", color = "cyan" } },
                { "<leader>h", group = "Git hunks", icon = { icon = "", color = "blue" } },
                { "<leader>p", group = "Window management", icon = { icon = "", color = "blue" } },
                { "<leader>s", group = "Sessions", icon = { icon = "󰆓", color = "azure" } },
                { "<leader>d", group = "Diagnostics", icon = { icon = "󱖫", color = "green" } },
                { "<leader>c", group = "Code", icon = { icon = "", color = "orange" } },
                { "<leader>cA", desc = "Web: TypeScript / ESLint actions" },
                { "<leader>cC", desc = "Web: Component, style, story, or test" },
                { "<leader>cI", desc = "Web: Open or create import file" },
                { "<leader>cN", desc = "Web: Run package script" },
                { "<leader>cP", desc = "Web: Find pages and routes" },
                { "<leader>cV", desc = "Web: Vite controls and live preview" },
                { "<leader>D", group = "Debug", icon = { icon = "󰃤", color = "red" } },
                { "<leader>x", group = "Trouble", icon = { icon = "󰒡", color = "red" } },
                { "<leader>v", group = "Buffers", icon = { icon = "󰈔", color = "cyan" } },
                { "<leader>m", group = "WPF", icon = { icon = "󰙨", color = "purple" } },
                { "<leader>n", group = "Diagnostic controls", icon = { icon = "󱖫", color = "green" } },
                { "<leader>u", group = "Interface", icon = { icon = "󰙵", color = "cyan" } },
                { "<leader>t", group = "Terminal", icon = { icon = "", color = "red" } },
                { "<leader>a", group = "AI", icon = { icon = "", color = "green" } },
            },

            win = {
                border = "rounded",
                -- Keep the menu bottom-aligned without moving it below a
                -- cursor near the bottom, which can clip its shortcut rows.
                row = -1,
                no_overlap = false,
                height = { min = 4, max = 0.75 },
            },

            layout = {
                width = { min = 20, max = 50 },
                spacing = 3,
            },
        },
    },
}
