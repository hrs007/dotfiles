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

            -- Columns displayed in the directory buffer.
            columns = {
                "icon",
                "size",
            },

            -- Use a vertical split when opening files from Oil.
            win_options = {
                wrap = false,
                signcolumn = "yes:2",
            },

            -- Skip confirmation when deleting files permanently.
            -- Keep this enabled for safety.
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
