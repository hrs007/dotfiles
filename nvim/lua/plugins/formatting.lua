return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },

        opts = {
            formatters_by_ft = {
                python = { "ruff_format" },
            },

            format_on_save = function(bufnr)
                return {
                    timeout_ms = 1000,
                    lsp_format = "never",
                }
            end,
        },
    },
}
