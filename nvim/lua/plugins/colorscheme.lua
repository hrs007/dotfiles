return {
    {
        "catppuccin/nvim",

        name = "catppuccin",

        priority = 1000,

        lazy = false,

        opts = {
            flavour = "mocha",

            transparent_background = false,

            term_colors = true,

            styles = {
                comments = { "italic" },
                conditionals = { "italic" },
                loops = {},
                functions = {},
                keywords = { "italic" },
                strings = {},
                variables = {},
            },

            integrations = {
                treesitter = true,
                native_lsp = {
                    enabled = true,
                    underlines = {
                        errors = { "underline" },
                        hints = { "underline" },
                        warnings = { "underline" },
                        information = { "underline" },
                    },
                },
                lualine = true,
                gitsigns = true,
                which_key = true,
                nvimtree = false,
                telescope = {
                    enabled = true,
                },
                cmp = true,
                blink_cmp = true,
            },
        },

        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin")
            vim.api.nvim_set_hl(0, "CursorLineNr", {
                fg = "#f9e2af",
                bg = "NONE",
                bold = true,
            })
        end,
    },
}
