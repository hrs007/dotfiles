return {
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "sindrets/diffview.nvim",
        },
        opts = {
            kind = "tab",
            floating = {
                border = "rounded",
            },
            integrations = {
                telescope = true,
                diffview = true,
            },
            sections = {
                recent = { folded = true },
                stashes = { folded = false },
            },
        },
        keys = {
            { "<leader>gg", "<Cmd>Neogit kind=tab<CR>", desc = "Git: Status" },
            { "<leader>gc", "<Cmd>Neogit commit<CR>", desc = "Git: Commit" },
            { "<leader>gp", "<Cmd>Neogit push<CR>", desc = "Git: Push" },
            { "<leader>gP", "<Cmd>Neogit pull<CR>", desc = "Git: Pull" },
            { "<leader>gs", "<Cmd>Neogit stash<CR>", desc = "Git: Stashes" },
            { "<leader>gl", "<Cmd>Neogit log<CR>", desc = "Git: Log" },
            { "<leader>gd", "<Cmd>DiffviewOpen<CR>", desc = "Git: Review changes" },
            { "<leader>gh", "<Cmd>DiffviewFileHistory %<CR>", desc = "Git: File history" },
            { "<leader>gH", "<Cmd>DiffviewFileHistory<CR>", desc = "Git: Repository history" },
        },
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewFileHistory" },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            enhanced_diff_hl = true,
        },
    },
}
