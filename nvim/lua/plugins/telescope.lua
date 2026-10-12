return {
    {
        -- Fuzzy finder for files, text, buffers, and more.
        "nvim-telescope/telescope.nvim",

        -- Pin the version for a predictable setup.
       -- tag = "0.1.8",

        -- Utility library required by Telescope.
        dependencies = {
            "nvim-lua/plenary.nvim",
        },

        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")

            -- Initialize Telescope.
            telescope.setup({
                defaults = {
                    layout_strategy = "flex",
                    layout_config = {
                        horizontal = {
                            prompt_position = "top",
                            preview_width = 0.55,
                        },
                        vertical = {
                            mirror = true,
                            preview_height = 0.4,
                        },
                        width = 0.86,
                        height = 0.80,
                    },
                    sorting_strategy = "ascending",
                    border = true,
                    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                },
            })

            -- Find files in the current working directory.
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {
                desc = "Find files",
            })

            -- Search text throughout the project.
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {
                desc = "Search project text",
            })

            -- Find currently open buffers.
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {
                desc = "Find buffers",
            })

            -- Search Neovim's help documentation.
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
                desc = "Search help",
            })
        end,
    },
}
