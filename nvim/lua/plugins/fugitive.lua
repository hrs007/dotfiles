return {
    {
        "tpope/vim-fugitive",

        cmd = {
            "Git",
            "G",
            "Gdiffsplit",
            "Gvdiffsplit",
            "Gread",
            "Gwrite",
            "Ggrep",
            "Glgrep",
            "GMove",
            "GDelete",
        },

        keys = {
            {
                "<leader>gg",
                "<cmd>Git<CR>",
                desc = "Open Git status",
            },
            {
                "<leader>gc",
                "<cmd>Git commit<CR>",
                desc = "Git commit",
            },
            {
                "<leader>gp",
                "<cmd>Git push<CR>",
                desc = "Git push",
            },
            {
                "<leader>gP",
                "<cmd>Git pull<CR>",
                desc = "Git pull",
            },
            {
                "<leader>gl",
                "<cmd>Git log --oneline --decorate --graph<CR>",
                desc = "Git log",
            },
        },
    },
}
