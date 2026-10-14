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

            -- When Neovim starts in home, open Oil at the current file's
            -- home-relative directory. Else preserve the original behavior
            -- and open Neovim's current working directory.
            vim.keymap.set("n", "<leader>e", function()
                local oil = require("oil")
                local cwd = vim.fs.normalize(vim.fn.getcwd())
                local home = vim.fs.normalize(vim.fn.expand("~"))
                local target = cwd

                if cwd == home then
                    local directory = vim.bo.filetype == "oil" and oil.get_current_dir() or nil
                    if not directory or directory == "" then
                        local file = vim.api.nvim_buf_get_name(0)
                        directory = file ~= "" and vim.fs.dirname(file) or home
                    end

                    target = vim.fn.fnamemodify(directory, ":~")
                    if target == "~" then
                        target = "."
                    elseif target:sub(1, 2) == "~/" then
                        target = target:sub(3)
                    end
                end

                oil.open(target)
            end, {
                desc = "Open current directory in Oil (home-relative)",
            })
        end,
    },
}
