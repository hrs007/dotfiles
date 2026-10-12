return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },

        opts = {
            formatters_by_ft = {
                python = { "ruff_format" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                cs = { "csharpier" },
            },

            format_on_save = function(bufnr)
                return {
                    timeout_ms = 5000,
                    -- XAML uses LemMinX's XML formatter; other files use
                    -- their configured external formatter only.
                    lsp_format = vim.bo[bufnr].filetype == "xml" and "fallback" or "never",
                }
            end,
        },
    },
}
