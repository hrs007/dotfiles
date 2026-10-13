local is_windows = vim.fn.has("win32") == 1
local formatters_by_ft = {
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
}

-- LazyGit is installed separately from Mason; Mason manages executable
-- formatters and debug adapters here.
local ensure_installed = {
    "prettier",
    "prettierd",
    "clang-format",
    "debugpy",
    "codelldb",
    "js-debug-adapter",
}
if is_windows then
    formatters_by_ft.cs = { "csharpier" }
    table.insert(ensure_installed, "csharpier")
end

return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },

        opts = function()
            local root_file = require("conform.util").root_file
            local web_markers = {
                "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs",
                ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml",
                ".editorconfig", "package.json",
            }

            return {
                formatters_by_ft = formatters_by_ft,
                -- Run each formatter from the nearest project configuration
                -- directory so project-local rules are discovered consistently.
                formatters = {
                    prettier = { cwd = root_file(web_markers) },
                    prettierd = { cwd = root_file(web_markers) },
                    ruff_format = {
                        cwd = root_file({ "ruff.toml", ".ruff.toml", "pyproject.toml" }),
                    },
                    clang_format = { cwd = root_file({ ".clang-format", "_clang-format" }) },
                },
                format_on_save = function(bufnr)
                    return {
                        timeout_ms = 5000,
                        -- XAML uses LemMinX's XML formatter; other files use
                        -- their configured external formatter only.
                        lsp_format = vim.bo[bufnr].filetype == "xml" and "fallback" or "never",
                    }
                end,
            }
        end,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        opts = {
            ensure_installed = ensure_installed,
            run_on_start = true,
            start_delay = 3000,
            debounce_hours = 24,
        },
    },
}
