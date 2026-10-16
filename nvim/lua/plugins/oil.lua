return {
    {
        "stevearc/oil.nvim",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        lazy = false,

        opts = {
            -- Display files and directories using icons.
            -- Do not auto-convert the startup directory into oil:// before
            -- Neovim's restart/session restore script reopens saved Oil panes.
            -- The explicit "-" and <leader>e mappings still open Oil normally.
            default_file_explorer = false,

            -- Keep Oil buffers hidden from the regular buffer list while
            -- retaining their contents when switching to another buffer.
            buf_options = {
                buflisted = false,
                bufhidden = "hide",
            },
            -- Show hidden files.
            view_options = {
                show_hidden = true,
            },

            -- Refresh open Oil buffers when files change outside Neovim.
            watch_for_changes = true,

            -- Notify attached language servers before/after file moves so
            -- TypeScript can rewrite imports. Auto-save only buffers that
            -- were clean before the workspace edit; modified buffers remain
            -- open with their LSP changes for the user to review and save.
            lsp_file_methods = {
                enabled = true,
                timeout_ms = 2000,
                autosave_changes = "unmodified",
            },

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

            -- Open Oil for an explicit directory argument such as `nvim .`.
            -- Do not reopen Oil merely because a restored buffer has an
            -- oil:// name; restart/session restoration should keep its state.
            vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("config.oil_startup", { clear = true }),
                once = true,
                callback = function()
                    local args = vim.fn.argv()
                    if #args ~= 1 then return end

                    local target = vim.fn.fnamemodify(args[1], ":p")
                    if vim.fn.isdirectory(target) ~= 1 then return end

                    local startup_buf = vim.api.nvim_get_current_buf()
                    vim.schedule(function()
                        vim.cmd("Oil " .. vim.fn.fnameescape(target))

                        -- Directory takeover is disabled, so remove Neovim's
                        -- original directory argument buffer after Oil opens.
                        if vim.api.nvim_buf_is_valid(startup_buf)
                            and startup_buf ~= vim.api.nvim_get_current_buf()
                            and vim.fn.bufwinid(startup_buf) == -1
                        then
                            local name = vim.api.nvim_buf_get_name(startup_buf)
                            if name ~= "" and vim.fn.isdirectory(name) == 1
                                and vim.bo[startup_buf].filetype ~= "oil"
                            then
                                pcall(vim.api.nvim_buf_delete, startup_buf, { force = true })
                            end
                        end
                    end)
                end,
                desc = "Open explicit command-line directories in Oil",
            })

            local transfer = require("config.oil_transfer")
            local function preserve_oil_buffer(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) then return end
                vim.bo[bufnr].bufhidden = "hide"
            end
            local function set_transfer_keymaps(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "oil" then return end
                preserve_oil_buffer(bufnr)
                vim.keymap.set({ "n", "x" }, "y", transfer.yank, {
                    buffer = bufnr,
                    desc = "Yank file paths for transfer",
                })
                vim.keymap.set("n", "yy", transfer.yank, {
                    buffer = bufnr,
                    desc = "Yank file paths for transfer",
                })
                vim.keymap.set({ "n", "x" }, "Y", transfer.yank, {
                    buffer = bufnr,
                    desc = "Yank file paths for transfer",
                })
                vim.keymap.set("n", "p", transfer.paste, {
                    buffer = bufnr,
                    desc = "Copy yanked files into this directory",
                })
                vim.keymap.set("n", "P", transfer.paste, {
                    buffer = bufnr,
                    desc = "Copy yanked files into this directory",
                })
            end
            local group = vim.api.nvim_create_augroup("config.oil_transfer_keymaps", { clear = true })
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "OilEnter",
                callback = function(event)
                    local bufnr = event.data and event.data.buf or vim.api.nvim_get_current_buf()
                    set_transfer_keymaps(bufnr)
                end,
            })
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                pattern = "oil",
                callback = function(event)
                    set_transfer_keymaps(event.buf)
                end,
            })
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                set_transfer_keymaps(bufnr)
            end

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
