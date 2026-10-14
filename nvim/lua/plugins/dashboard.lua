return {
    {
        "nvimdev/dashboard-nvim",
        -- Load only when the dashboard is explicitly requested. Startup is
        -- handled by config.dashboard_startup after a short file-open grace
        -- period, so Neovide can deliver Finder's open-document event first.
        cmd = "Dashboard",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local dashboard_group = vim.api.nvim_create_augroup("DashboardFileOpen", { clear = true })

            local function file_buffer(bufnr)
                return vim.api.nvim_buf_is_valid(bufnr)
                    and vim.api.nvim_buf_is_loaded(bufnr)
                    and vim.api.nvim_buf_get_name(bufnr) ~= ""
                    and vim.bo[bufnr].buftype == ""
                    and vim.bo[bufnr].filetype ~= "dashboard"
            end

            local function reveal_file_over_dashboard(bufnr)
                if not file_buffer(bufnr) then
                    return
                end

                for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
                    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
                        local visible = vim.api.nvim_win_get_buf(winid)
                        if vim.bo[visible].filetype == "dashboard" then
                            vim.api.nvim_win_set_buf(winid, bufnr)
                            vim.api.nvim_set_current_win(winid)
                            return
                        end
                    end
                end
            end

            require("dashboard").setup({
                theme = "hyper",
                -- Keep recent-item hotkeys beside each entry instead of at
                -- the far edge of a wide Neovide window.
                shortcuts_left_side = true,
                change_to_vcs_root = true,

                config = {
                    header = {
                        "",
                        "  ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
                        "  ████╗  ██║██║   ██║██║████╗ ████║",
                        "  ██╔██╗ ██║██║   ██║██║██╔████╔██║",
                        "  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                        "  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
                        "  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
                        "",
                    },

                    shortcut = {
                        {
                            desc = "Find File",
                            group = "Label",
                            action = "Telescope find_files",
                            key = "f",
                        },
                        {
                            desc = "Find Text",
                            group = "Label",
                            action = "Telescope live_grep",
                            key = "g",
                        },
                        {
                            desc = "Recent Files",
                            group = "Label",
                            action = "Telescope oldfiles",
                            key = "r",
                        },
                        {
                            desc = "New File",
                            group = "Label",
                            action = "enew",
                            key = "n",
                        },
                        {
                            desc = "Plugin Manager",
                            group = "Label",
                            action = "Lazy",
                            key = "l",
                        },
                        {
                            desc = "Quit Neovim",
                            group = "Label",
                            action = "qa",
                            key = "q",
                        },
                    },

                    project = {
                        enable = true,
                        -- dashboard-nvim's current slice includes one extra
                        -- project, so four keeps the visible list to five.
                        limit = 4,
                        label = " Recent Projects",
                        action = "Telescope find_files cwd=",
                    },

                    mru = {
                        enable = true,
                        limit = 8,
                        label = " Recent Files",
                        cwd_only = false,
                    },

                    footer = {
                        "",
                        "Happy coding!",
                    },
                },
            })

            -- The dashboard can be created after a file buffer was loaded, or
            -- Finder can deliver its open-file event after Neovide's UIEnter.
            -- In either order, make the real file replace any visible dashboard.
            vim.api.nvim_create_autocmd("User", {
                group = dashboard_group,
                pattern = "DashboardLoaded",
                callback = function()
                    local buffers = vim.api.nvim_list_bufs()
                    for index = #buffers, 1, -1 do
                        if file_buffer(buffers[index]) then
                            reveal_file_over_dashboard(buffers[index])
                            return
                        end
                    end
                end,
                desc = "Prefer a loaded file over the startup dashboard",
            })

            vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
                group = dashboard_group,
                callback = function(event)
                    vim.schedule(function()
                        reveal_file_over_dashboard(event.buf)
                    end)
                end,
                desc = "Show files opened over the startup dashboard",
            })
        end,
    },
}
