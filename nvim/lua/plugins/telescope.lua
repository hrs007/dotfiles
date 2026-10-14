return {
    {
        -- Fuzzy finder for files, text, buffers, and more.
        "nvim-telescope/telescope.nvim",

        -- Utility library required by Telescope.
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond = function()
                    return vim.fn.executable("make") == 1
                end,
            },
        },

        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")
            local actions = require("telescope.actions")

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
                    filesize_limit = 0.5, -- Skip previews of files larger than 0.5 MB.
                    sorting_strategy = "ascending",
                    border = true,
                    borderchars = {
                        "─", "│", "─", "│",
                        "╭", "╮", "╯", "╰",
                    },
                    mappings = {
                        i = {
                            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                        },
                        n = {
                            ["q"] = actions.close,
                            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                        },
                    },
                },

pickers = {
    find_files = {
        hidden = false,
        no_ignore = false,
        previewer = false,

        find_command = {
            "rg",
            "--files",
            "--color",
            "never",
            "--glob", "!**/.git/**",
            "--glob", "!**/.venv/**",
            "--glob", "!**/venv/**",
            "--glob", "!**/env/**",
            "--glob", "!**/node_modules/**",
            "--glob", "!**/__pycache__/**",
            "--glob", "!**/build/**",
            "--glob", "!**/dist/**",
            "--glob", "!**/.mypy_cache/**",
            "--glob", "!**/.pytest_cache/**",
        },
    },
},
            })

            pcall(telescope.load_extension, "fzf")

            -- Find files in the current working directory.
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {
                desc = "Find files",
            })

            -- Search text throughout the project.
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {
                desc = "Search project text",
            })

            -- Switch quickly among currently open files, most recently used first.
            vim.keymap.set("n", "<leader>fb", function()
                builtin.buffers({ sort_mru = true, ignore_current_buffer = true })
            end, {
                desc = "Recent buffers",
            })

            -- Search Neovim's help documentation.
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, {
                desc = "Search help",
            })
        end,
    },
}
