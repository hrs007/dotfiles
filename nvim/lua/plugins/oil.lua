return {
    {
        "stevearc/oil.nvim",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        lazy = false,

        opts = {
            -- Display files and directories using icons.
            default_file_explorer = true,

            -- Show hidden files.
            view_options = {
                show_hidden = true,
            },

            -- Refresh open Oil buffers when files change outside Neovim.
            watch_for_changes = true,

            columns = { "icon" },
            win_options = {
                wrap = false,
                signcolumn = "no",
            },
            delete_to_trash = true,
            keymaps = {
                ["q"] = "actions.close",
            },
        },

        config = function(_, opts)
            require("oil").setup(opts)

            -- Open Oil in the current directory.
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
                desc = "Open parent directory",
            })

            -- Open Oil at the current working directory.
            vim.keymap.set("n", "<leader>e", function()
                require("oil").open(vim.fn.getcwd())
            end, {
                desc = "Open file explorer",
            })
        end,
    },
}
