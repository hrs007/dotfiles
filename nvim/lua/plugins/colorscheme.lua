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

            -- Make Diffview's line-level changes stand out against the
            -- Catppuccin background while keeping the text easy to read.
            vim.api.nvim_set_hl(0, "DiffAdd", {
                fg = "#c6f3c0",
                bg = "#244238",
            })
            vim.api.nvim_set_hl(0, "DiffDelete", {
                fg = "#f6b6c2",
                bg = "#4a2935",
            })
            vim.api.nvim_set_hl(0, "DiffChange", {
                fg = "#f5e6b8",
                bg = "#39334b",
            })
            vim.api.nvim_set_hl(0, "DiffText", {
                fg = "#1e1e2e",
                bg = "#fab387",
                bold = true,
            })
            -- Diffview uses this group for the non-changing side of a hunk.
            -- Keep it neutral so older in-session theme values cannot tint
            -- unchanged lines after a config reload.
            vim.api.nvim_set_hl(0, "DiffviewDiffDeleteDim", { link = "Comment" })
            vim.api.nvim_set_hl(0, "DiffviewFilePanelInsertions", {
                fg = "#a6e3a1",
                bg = "NONE",
                bold = true,
            })
            vim.api.nvim_set_hl(0, "DiffviewFilePanelDeletions", {
                fg = "#f38ba8",
                bg = "NONE",
                bold = true,
            })
            -- LSP servers mark unused symbols with the `unused` semantic
            -- token modifier and/or DiagnosticUnnecessary. Use one muted
            -- style for both paths across languages.
            vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
                fg = "#6c7086",
                italic = true,
            })
            vim.api.nvim_set_hl(0, "ConfigUnusedSymbol", {
                fg = "#6c7086",
                italic = true,
            })
            vim.api.nvim_set_hl(0, "ConfigReferenceCount", {
                fg = "#585b70",
                italic = true,
            })
            -- Python's reference scanner handles unused method definitions
            -- and skips inherited methods that may be called by a framework.
            for _, group in ipairs({
                "@lsp.typemod.variable.unused",
                "@lsp.typemod.parameter.unused",
                "@lsp.typemod.function.unused",
                "@lsp.typemod.property.unused",
                "@lsp.typemod.field.unused",
                "@lsp.typemod.type.unused",
                "@lsp.typemod.class.unused",
            }) do
                vim.api.nvim_set_hl(0, group, {
                    fg = "#6c7086",
                    italic = true,
                })
            end
        end,
    },
}
