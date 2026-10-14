return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = "VeryLazy",
        opts = function()
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
                    lualine_b = {
                        {
                            "branch",
                            -- Lualine adds its own branch glyph unless icon is set.
                            icon = "",
                            color = { fg = "#89b4fa", gui = "bold" },
                            padding = { left = 1, right = 1 },
                            separator = "",
                            fmt = function(branch)
                                local max_chars = 28
                                if vim.fn.strchars(branch) > max_chars then
                                    return vim.fn.strcharpart(branch, 0, max_chars - 1) .. "…"
                                end
                                return branch
                            end,
                        },
                    },
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
                    lualine_x = { "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
}
