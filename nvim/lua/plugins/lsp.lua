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
                "lua_ls",       -- Lua
            },

            -- Automatically enable installed servers.
            automatic_enable = true,
        },

        config = function(_, opts)
            -- Enable nvim-cmp completion capabilities for LSP servers.
            vim.lsp.config("*", {
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
            })

            ----------------------------------------------------------------
            -- Python LSP root detection
            ----------------------------------------------------------------

            local home = vim.fs.normalize(vim.fn.expand("~"))

            local function set_python_root(bufnr, on_dir, markers)
                local file = vim.api.nvim_buf_get_name(bufnr)

                if file == "" then
                    return
                end

                -- Find the nearest project marker.
                local root = vim.fs.root(file, markers)

                -- Avoid treating the home directory as every project's root.
                if root
                    and vim.fs.normalize(root):lower() == home:lower()
                then
                    local cwd = vim.fs.normalize(vim.fn.getcwd())
                    local normalized_file =
                        vim.fs.normalize(file):gsub("\\", "/"):lower()
                    local normalized_cwd =
                        cwd:gsub("\\", "/"):lower()

                    if normalized_file:sub(1, #normalized_cwd + 1)
                        == normalized_cwd .. "/"
                    then
                        root = cwd
                    else
                        root = vim.fs.dirname(file)
                    end
                end

                root = root or vim.fs.dirname(file)

                if root then
                    on_dir(root)
                end
            end

            ----------------------------------------------------------------
            -- BasedPyright: Python type checking
            ----------------------------------------------------------------

            vim.lsp.config("basedpyright", {
                root_dir = function(bufnr, on_dir)
                    set_python_root(bufnr, on_dir, {
                        "pyrightconfig.json",
                        "pyproject.toml",
                        "setup.py",
                        "setup.cfg",
                        "requirements.txt",
                        "Pipfile",
                        ".git",
                    })
                end,

                settings = {
                    basedpyright = {
                        analysis = {
                            autoSearchPaths = true,
                            diagnosticMode = "openFilesOnly",

                            -- Exclude large directories from analysis.
                            exclude = {
                                "**/.git",
                                "**/.venv",
                                "**/venv",
                                "**/env",
                                "**/AppData",
                                "**/node_modules",
                                "**/__pycache__",
                                "**/build",
                                "**/dist",
                                "**/.mypy_cache",
                                "**/.pytest_cache",
                            },
                        },
                    },
                },
            })

            ----------------------------------------------------------------
            -- Ruff: Python linting
            ----------------------------------------------------------------

            vim.lsp.config("ruff", {
                root_dir = function(bufnr, on_dir)
                    set_python_root(bufnr, on_dir, {
                        "ruff.toml",
                        ".ruff.toml",
                        "pyproject.toml",
                        ".git",
                    })
                end,
            })

            ----------------------------------------------------------------
            -- Lua language server
            ----------------------------------------------------------------

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
