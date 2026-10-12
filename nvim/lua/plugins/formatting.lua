return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },

        opts = {
            formatters_by_ft = {
                python = { "ruff_format" },
                javascript = { "prettier", "prettierd", stop_after_first = true },
                javascriptreact = { "prettier", "prettierd", stop_after_first = true },
                typescript = { "prettier", "prettierd", stop_after_first = true },
                typescriptreact = { "prettier", "prettierd", stop_after_first = true },
                html = { "prettier", "prettierd", stop_after_first = true },
                css = { "prettier", "prettierd", stop_after_first = true },
                scss = { "prettier", "prettierd", stop_after_first = true },
                json = { "prettier", "prettierd", stop_after_first = true },
                jsonc = { "prettier", "prettierd", stop_after_first = true },
                yaml = { "prettier", "prettierd", stop_after_first = true },
                markdown = { "prettier", "prettierd", stop_after_first = true },
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
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = { "prettier", "prettierd", "lazygit" },
            run_on_start = true,
            start_delay = 3000,
            debounce_hours = 24,
        },
    },
}
