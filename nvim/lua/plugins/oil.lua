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

            -- A directory passed on the command line should open in Oil.
            -- Bare `nvim` startup is handled separately by the dashboard.
            vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("config.oil_startup", { clear = true }),
                once = true,
                callback = function()
                    local args = vim.fn.argv()
                    if #args ~= 1 then return end

                    local target = vim.fn.fnamemodify(args[1], ":p")
                    if vim.fn.isdirectory(target) == 1 then
                        -- Run after Neovim finishes opening startup arguments;
                        -- otherwise its initial empty buffer can replace Oil.
                        vim.schedule(function()
                            vim.cmd("Oil " .. vim.fn.fnameescape(target))
                        end)
                    end
                end,
                desc = "Open command-line directories in Oil",
            })

            local transfer = require("config.oil_transfer")
            local function cycle_from_oil(direction)
                local buffers = {}
                for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
                    if info.loaded and vim.api.nvim_buf_is_valid(info.bufnr) then
                        buffers[#buffers + 1] = info.bufnr
                    end
                end
                table.sort(buffers)
                if #buffers == 0 then return end

                local base
                local ok, original = pcall(vim.api.nvim_win_get_var, 0, "oil_original_buffer")
                if ok then base = original end
                local index
                for i, bufnr in ipairs(buffers) do
                    if bufnr == base then index = i; break end
                end
                if not index then
                    local alternate = vim.fn.bufnr("#")
                    for i, bufnr in ipairs(buffers) do
                        if bufnr == alternate then index = i; break end
                    end
                end
                if not index then index = direction > 0 and 0 or (#buffers + 1) end
                local target = ((index - 1 + direction) % #buffers) + 1
                if #buffers == 1 and buffers[target] == vim.api.nvim_get_current_buf() then
                    vim.notify("No other listed buffers to switch to.", vim.log.levels.INFO)
                    return
                end
                vim.api.nvim_set_current_buf(buffers[target])
            end
            local function set_transfer_keymaps(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= "oil" then return end
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
                vim.keymap.set("n", "<S-h>", function() cycle_from_oil(-1) end, {
                    buffer = bufnr,
                    desc = "Buffer: Previous from Oil",
                })
                vim.keymap.set("n", "<S-l>", function() cycle_from_oil(1) end, {
                    buffer = bufnr,
                    desc = "Buffer: Next from Oil",
                })
            end
            local group = vim.api.nvim_create_augroup("config.oil_transfer_keymaps", { clear = true })
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "OilEnter",
                callback = function(event)
                    set_transfer_keymaps(event.data and event.data.buf or vim.api.nvim_get_current_buf())
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
