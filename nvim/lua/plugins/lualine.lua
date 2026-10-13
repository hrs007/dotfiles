return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "SmiteshP/nvim-navic",
        },
        event = "VeryLazy",
        opts = function()
            local function copilot_active()
                local client = package.loaded["copilot.client"]
                return client ~= nil
                    and not client.is_disabled()
                    and client.buf_is_attached(vim.api.nvim_get_current_buf())
            end

            local function breadcrumb()
                local navic = package.loaded["nvim-navic"]
                if not navic or not navic.is_available() then
                    -- Keep the winbar row present while LSP symbols load or
                    -- when the cursor is outside a symbol.
                    return " "
                end

                local location = navic.get_location()
                return location ~= "" and location or " "
            end

            return {
                refresh = {
                    statusline = 1000,
                },
                options = {
                    theme = "auto",
                    globalstatus = true,
                    component_separators = { left = "│", right = "│" },
                    section_separators = { left = "", right = "" },
                    disabled_filetypes = {
                        statusline = { "oil" },
                    },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch" },
                    lualine_c = {
                        {
                            "filename",
                            -- Show the file's path relative to the working directory
                            -- in the existing statusline, without adding another row.
                            path = 1,
                            symbols = { modified = " ●", readonly = " RO" },
                        },
                        "diagnostics",
                    },
                    lualine_x = {
                        {
                            function()
                                return ""
                            end,
                            color = function()
                                return {
                                    fg = copilot_active() and "#a6e3a1" or "#6c7086",
                                }
                            end,
                            separator = "",
                            padding = { left = 1, right = 1 },
                        },
                        "filetype",
                    },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
                winbar = {
                    lualine_c = {
                        {
                            breadcrumb,
                            color = { fg = "#a6adc8" },
                        },
                    },
                },
                inactive_winbar = {
                    lualine_c = {
                        {
                            breadcrumb,
                            color = { fg = "#a6adc8" },
                        },
                    },
                },
            }
        end,
    },
}
