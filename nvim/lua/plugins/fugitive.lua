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
            { "<leader>gF", "<Cmd>Git<CR>", desc = "Git: Fugitive status" },
            { "<leader>gB", "<Cmd>Git blame<CR>", desc = "Git: Blame file" },
            { "<leader>gD", "<Cmd>Gdiffsplit<CR>", desc = "Git: Diff current file" },
            { "<leader>gL", "<Cmd>Git log --oneline --decorate --graph<CR>", desc = "Git: Repository log" },
            { "<leader>gC", "<Cmd>Git commit<CR>", desc = "Git: Commit with Fugitive" },
        },

        config = function()
            local group = vim.api.nvim_create_augroup("FugitiveMappings", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                pattern = "fugitive",
                callback = function(event)
                    vim.keymap.set("n", "q", "gq", {
                        buffer = event.buf,
                        remap = true,
                        desc = "Close Fugitive status",
                    })
                end,
            })
        end,
    },
}
