local is_windows = vim.fn.has("win32") == 1
local formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    css = { "prettierd", "prettier", stop_after_first = true },
    scss = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    jsonc = { "prettierd", "prettier", stop_after_first = true },
    yaml = { "prettierd", "prettier", stop_after_first = true },
    markdown = { "prettierd", "prettier", stop_after_first = true },
    c = { "clang_format" },
    cpp = { "clang_format" },
}

-- Mason manages executable formatters and debug adapters here.
local ensure_installed = {
    "stylua",
    "prettierd",
    "prettier",
    "clang-format",
    "debugpy",
    "codelldb",
    "js-debug-adapter",
}
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
                    return require("config.formatting").format_on_save(bufnr)
                end,
                format_after_save = function(bufnr)
                    return require("config.formatting").format_after_save(bufnr)
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
