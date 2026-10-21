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
        init = function()
            -- Fugitive command panels can use different filetypes, so also
            -- recognize Fugitive's own buffer-name scheme. This covers Git
            -- status, log, diff, blame, and other command output buffers.
            vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
                callback = function(event)
                    local buf = event.buf
                    local filetype = vim.bo[buf].filetype
                    local name = vim.api.nvim_buf_get_name(buf)
                    local fugitive_buffer = filetype == "fugitive"
                        or filetype == "fugitiveblame"
                        or name:match("^fugitive://") ~= nil
                    if not fugitive_buffer then return end

                    vim.keymap.set("n", "q", "<cmd>close<CR>", {
                        buffer = buf,
                        silent = true,
                        desc = "Fugitive: Close panel",
                    })
                    vim.keymap.set("n", "<leader>pz", function()
                        require("config.window_zoom").toggle()
                    end, {
                        buffer = buf,
                        silent = true,
                        desc = "Window: Zoom / restore split",
                    })
                end,
            })
        end,
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
