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
                    -- Lualine renders its sections in a single line in Neovide.
                    -- Avoid extra spacing options that can inflate its bar.
                    disabled_filetypes = {
                        statusline = { "oil" },
                    },
                },
                sections = {
                    lualine_a = {
                        "mode",
                        {
                            "macro recording",
                            fmt = function()
                                local register = vim.fn.reg_recording()
                                return register ~= "" and ("REC @" .. register) or ""
                            end,
                            color = { fg = "#f38ba8", gui = "bold" },
                        },
                    },
                    lualine_b = {
                        {
                            "branch",
                            icon = "",
                            color = { fg = "#f5c2e7", bg = "#313244", gui = "bold" },
                        },
                        {
                            "diff",
                            symbols = { added = "+", modified = "~", removed = "-" },
                            colored = true,
                            source = function()
                                local gitsigns = vim.b.gitsigns_status_dict
                                if gitsigns then
                                    return {
                                        added = gitsigns.added,
                                        modified = gitsigns.changed,
                                        removed = gitsigns.removed,
                                    }
                                end
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
                        "searchcount",
                        {
                            "diagnostics",
                            sources = { "nvim_diagnostic" },
                            sections = { "error", "warn", "hint" },
                            symbols = { error = "E:", warn = "W:", hint = "H:" },
                            colored = true,
                            update_in_insert = false,
                        },
                    },
                    lualine_x = {
                        {
                            "filetype",
                            -- Use the section highlight for icons so filetype
                            -- glyph backgrounds cannot diverge from the bar.
                            colored = false,
                        },
                    },
                    lualine_y = {
                        {
                            "progress",
                            color = { fg = "#c0c7d2", bg = "#000000" },
                        },
                    },
                    lualine_z = {
                        {
                            "selectioncount",
                            fmt = function(count)
                                return count ~= "" and ("Sel " .. count) or ""
                            end,
                        },
                        "location",
                    },
                },
            }
        end,
    },
}
