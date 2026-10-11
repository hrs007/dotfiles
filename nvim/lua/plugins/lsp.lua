return {
    {
        -- Install and manage language servers, debuggers, and formatters.
        "mason-org/mason.nvim",

        -- Load Mason during startup.
        lazy = false,

        opts = {},
    },

    {
        -- Connect Mason with Neovim's built-in LSP.
        "mason-org/mason-lspconfig.nvim",

        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
        },

        -- Language servers to install.
        opts = {
            ensure_installed = {
                "basedpyright", -- Python type checking
                "ruff",         -- Python linting
                "clangd",       -- C and C++
                "ts_ls",        -- JavaScript and TypeScript
                "html",         -- HTML
                "cssls",        -- CSS
                "jsonls",       -- JSON
                "yamlls",       -- YAML
                "lua_ls",       -- Lua (optional)
            },

            -- Automatically enable installed servers.
            automatic_enable = true,
        },

        config = function(_, opts)
            -- Enable nvim-cmp completion capabilities for LSP servers.
            vim.lsp.config("*", {
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
            })

            -- Configure Lua language server.
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = {
                            -- Neovim uses LuaJIT.
                            version = "LuaJIT",
                        },

                        diagnostics = {
                            -- Recognize Neovim's global variable.
                            globals = { "vim" },
                        },

                        workspace = {
                            -- Make Neovim's API available to lua_ls.
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },

                        telemetry = {
                            enable = false,
                        },
                    },
                },
            })

            -- Initialize Mason-LSPConfig.
            require("mason-lspconfig").setup(opts)
        end,
    },
}
