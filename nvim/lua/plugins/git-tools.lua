return {
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        keys = {
            { "<leader>gg", "<cmd>Neogit<cr>", desc = "Open Neogit" },
        },
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("neogit").setup({})
        end,
    },
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "G" },
        keys = {
            { "<leader>gf", "<cmd>Git<cr>", desc = "Open Fugitive status" },
        },
    },
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        keys = {
            { "<leader>gl", "<cmd>LazyGit<cr>", desc = "Open Lazygit" },
        },
        dependencies = { "nvim-lua/plenary.nvim" },
    },
}
