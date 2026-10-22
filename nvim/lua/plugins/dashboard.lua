return {
    {
        "nvimdev/dashboard-nvim",
        -- The configured dashboard loads on demand through :Dashboard.
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

                local file_win = vim.fn.bufwinid(bufnr)
                for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
                    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
                        local visible = vim.api.nvim_win_get_buf(winid)
                        if vim.bo[visible].filetype == "dashboard" then
                            vim.api.nvim_win_set_buf(winid, bufnr)
                            file_win = file_win ~= -1 and file_win or winid
                        end
                    end
                end

                if file_win and file_win ~= -1 and vim.api.nvim_win_is_valid(file_win) then
                    vim.api.nvim_set_current_win(file_win)
                end
            end

            require("dashboard").setup({
                theme = "hyper",
                -- Keep the shared statusline and bufferline visible on the dashboard.
                hide = {
                    statusline = false,
                    tabline = false,
                    winbar = false,
                },
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
                            desc = "File Explorer",
                            group = "Label",
                            action = "Oil",
                            key = "e",
                        },
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
                            desc = "Recent Projects",
                            group = "Label",
                            action = "lua require('config.dashboard_projects').pick()",
                            key = "p",
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

            -- Keep the dashboard open when invoked manually from a file buffer.
            -- Files opened afterward still replace it through the autocmd below.
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter", "BufWinEnter" }, {
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
