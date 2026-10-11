return {
    {
        "nvim-lualine/lualine.nvim",

        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },

        event = "VeryLazy",

        opts = {
            options = {
                theme = "auto",
                globalstatus = true,
                component_separators = {
                    left = "│",
                    right = "│",
                },
                section_separators = {
                    left = "",
                    right = "",
                },
                disabled_filetypes = {
                    statusline = {
                        "oil",
                    },
                },
            },

            sections = {
                lualine_a = {
                    "mode",
                },

                lualine_b = {
                    "branch",
                    "diff",
                    "diagnostics",
                },

                lualine_c = {
                    {
                        "filename",
                        path = 1,
                    },
                },

                lualine_x = {
                    "encoding",
                    "filetype",
                },

                lualine_y = {
                    "progress",
                },

                lualine_z = {
                    "location",
                },
            },
        },
    },
}
