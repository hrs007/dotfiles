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

            -- Deutan-friendly diff colors: blue for additions, yellow for
            -- edits, and orange for deletions, with clear background blocks.
            local diff_highlights = {
                DiffAdd = { fg = "#cdd6f4", bg = "#263b55" },
                DiffChange = { fg = "#f9e2af", bg = "#49402b" },
                DiffDelete = { fg = "#fab387", bg = "#50352c" },
                DiffText = { fg = "#1e1e2e", bg = "#f9e2af", bold = true },
                GitSignsAdd = { fg = "#89b4fa", bold = true },
                GitSignsChange = { fg = "#f9e2af", bold = true },
                GitSignsDelete = { fg = "#fab387", bold = true },
                GitSignsChangedelete = { fg = "#fab387", bold = true },
                GitSignsTopdelete = { fg = "#fab387", bold = true },
                GitSignsUntracked = { fg = "#94e2d5", bold = true },
                GitSignsStagedAdd = { fg = "#89dceb", bold = true },
                GitSignsStagedChange = { fg = "#cba6f7", bold = true },
                GitSignsStagedDelete = { fg = "#fab387", bold = true },
                GitSignsStagedChangedelete = { fg = "#fab387", bold = true },
                GitSignsStagedTopdelete = { fg = "#fab387", bold = true },
            }
            for group, highlight in pairs(diff_highlights) do
                vim.api.nvim_set_hl(0, group, highlight)
            end

            vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#585b70", bold = true })

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
