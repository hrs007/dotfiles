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

            -- Restart/session scripts can restore an Oil buffer with `:file`
            -- while startup has already created an unmodified Oil buffer for
            -- the same directory. Remove that stale duplicate before Neovim
            -- assigns the restored buffer its name (which otherwise fails E95).
            vim.api.nvim_create_autocmd("BufFilePre", {
                group = vim.api.nvim_create_augroup("config.oil_session_name", { clear = true }),
                callback = function(event)
                    local target = event.file or event.match or ""
                    if not target:match("^oil://") then return end

                    local restoring_buf = event.buf
                    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                        if bufnr ~= restoring_buf
                            and vim.api.nvim_buf_is_valid(bufnr)
                            and vim.api.nvim_buf_get_name(bufnr) == target
                            and vim.bo[bufnr].filetype == "oil"
                            and not vim.bo[bufnr].modified
                        then
                            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
                        end
                    end
                end,
                desc = "Allow restored Oil buffers to reuse their saved URI",
            })

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
            local function select_oil_entry()
                local oil = require("oil")
                local api = vim.api
                local oil_win = api.nvim_get_current_win()
                if not vim.w[oil_win].config_oil_side_panel then
                    return oil.select()
                end

                local entry = oil.get_cursor_entry()
                if not entry or entry.type == "directory" then
                    return oil.select()
                end

                local target_win = vim.w[oil_win].config_oil_side_panel_origin
                if not target_win or not api.nvim_win_is_valid(target_win) or target_win == oil_win then
                    target_win = nil
                    for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
                        if win ~= oil_win and vim.bo[api.nvim_win_get_buf(win)].filetype ~= "oil" then
                            target_win = win
                            break
                        end
                    end
                end

                if not target_win then
                    vim.cmd("rightbelow vsplit")
                    target_win = api.nvim_get_current_win()
                    api.nvim_set_current_win(oil_win)
                end

                return oil.select({
                    handle_buffer_callback = function(bufnr)
                        if api.nvim_win_is_valid(target_win) then
                            api.nvim_win_set_buf(target_win, bufnr)
                            api.nvim_set_current_win(target_win)
                        end
                    end,
                })
            end

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
                vim.keymap.set("n", "<CR>", select_oil_entry, {
                    buffer = bufnr,
                    desc = "Open file in editor; browse folders here",
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

            local function toggle_oil_side_panel()
                local api = vim.api
                local oil = require("oil")
                local current_win = api.nvim_get_current_win()

                for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
                    if api.nvim_win_is_valid(win) and vim.w[win].config_oil_side_panel then
                        local return_win = vim.w[win].config_oil_side_panel_origin
                        api.nvim_win_close(win, true)
                        if return_win and api.nvim_win_is_valid(return_win) then
                            api.nvim_set_current_win(return_win)
                        elseif api.nvim_win_is_valid(current_win)
                            and vim.bo[api.nvim_win_get_buf(current_win)].filetype ~= "oil"
                        then
                            api.nvim_set_current_win(current_win)
                        end
                        return
                    end
                end

                local bufnr = api.nvim_get_current_buf()
                local name = api.nvim_buf_get_name(bufnr)
                local directory
                if vim.bo[bufnr].filetype == "oil" then
                    directory = oil.get_current_dir(bufnr)
                elseif name ~= "" and vim.fn.isdirectory(name) == 1 then
                    directory = name
                elseif name ~= "" then
                    directory = vim.fs.dirname(name)
                else
                    directory = vim.fn.getcwd()
                end

                vim.cmd("topleft 32vsplit")
                local panel_win = api.nvim_get_current_win()
                oil.open(directory)
                vim.w[panel_win].config_oil_side_panel = true
                vim.w[panel_win].config_oil_side_panel_origin = current_win
                pcall(api.nvim_win_set_width, panel_win, 32)
            end

            vim.keymap.set("n", "<leader>o", toggle_oil_side_panel, {
                desc = "Toggle Oil side panel",
            })

            vim.keymap.set("n", "<leader>O", function()
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    if vim.api.nvim_win_is_valid(win) and vim.w[win].config_oil_side_panel then
                        vim.api.nvim_set_current_win(win)
                        return
                    end
                end
                vim.notify("Oil side panel is not open.", vim.log.levels.INFO)
            end, {
                desc = "Focus Oil side panel",
            })
        end,
    },
}
