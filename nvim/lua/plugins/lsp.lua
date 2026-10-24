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
            "saghen/blink.cmp",
        },

        -- Language servers to install.
        opts = {
            ensure_installed = {
                "ty",            -- Python type checking and language features
                "ruff",         -- Python linting
                "clangd",       -- C and C++
                "ts_ls",        -- JavaScript and TypeScript
                "html",         -- HTML
                "cssls",        -- CSS
                "tailwindcss",  -- Tailwind CSS class completion and diagnostics
                "emmet_language_server", -- Emmet abbreviations in markup and JSX
                "eslint",       -- JavaScript and TypeScript linting and fixes
                "jsonls",       -- JSON
                "yamlls",       -- YAML
                "lua_ls",       -- Lua
                "lemminx",      -- XML and XAML
            },

            -- Automatically enable installed servers.
            automatic_enable = true,
        },

        config = function(_, opts)
            -- Enable Blink completion and LSP file-operation capabilities so
            -- Oil can ask TypeScript servers to rewrite imports on moves.
            local capabilities = require("blink.cmp").get_lsp_capabilities()
            capabilities.textDocument = vim.tbl_deep_extend("force", capabilities.textDocument or {}, {
                foldingRange = {
                    dynamicRegistration = false,
                    lineFoldingOnly = true,
                },
            })
            capabilities.workspace = vim.tbl_deep_extend("force", capabilities.workspace or {}, {
                fileOperations = {
                    dynamicRegistration = false,
                    willRename = true,
                    didRename = true,
                    willCreate = true,
                    didCreate = true,
                    willDelete = true,
                    didDelete = true,
                },
            })
            vim.lsp.config("*", { capabilities = capabilities })

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

            local function set_project_root(bufnr, on_dir, markers)
                local file = vim.api.nvim_buf_get_name(bufnr)
                if file == "" then
                    return
                end
                on_dir(vim.fs.root(file, markers) or vim.fs.dirname(file))
            end

            ----------------------------------------------------------------
            -- ty: Python type checking and language features
            ----------------------------------------------------------------

            vim.lsp.config("ty", {
                cmd = { "ty", "server" },
                root_dir = function(bufnr, on_dir)
                    set_python_root(bufnr, on_dir, {
                        "ty.toml",
                        "pyproject.toml",
                        "setup.py",
                        "setup.cfg",
                        "requirements.txt",
                        "Pipfile",
                        ".git",
                    })
                end,
                on_init = function(client)
                    local python = require("config.python")
                    local interpreter = python.resolve(client.config.root_dir)
                    local updates = {
                        ty = {
                            diagnosticMode = python.ty_diagnostics_enabled(client.config.root_dir)
                                    and "openFilesOnly" or "off",
                        },
                    }
                    if interpreter then
                        updates.ty.configuration = { environment = { python = interpreter } }
                    end
                    client.config.settings = vim.tbl_deep_extend(
                        "force",
                        client.config.settings or {},
                        updates
                    )
                    client:notify("workspace/didChangeConfiguration", {
                        settings = client.config.settings,
                    })
                end,
                settings = {
                    ty = {
                        diagnosticMode = "openFilesOnly",
                        inlayHints = {
                            variableTypes = true,
                            callArgumentNames = true,
                        },
                    },
                },
            })
            vim.lsp.enable("ty")

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

            -- Keep ESLint attached to the nearest frontend project so each
            -- package uses its own lint config in monorepos.
            vim.lsp.config("eslint", {
                root_dir = function(bufnr, on_dir)
                    set_project_root(bufnr, on_dir, {
                        "eslint.config.js",
                        "eslint.config.mjs",
                        "eslint.config.cjs",
                        ".eslintrc",
                        ".eslintrc.js",
                        ".eslintrc.cjs",
                        ".eslintrc.json",
                        "package.json",
                        ".git",
                    })
                end,
            })

            ----------------------------------------------------------------
            -- Tailwind CSS IntelliSense
            ----------------------------------------------------------------

            vim.lsp.config("tailwindcss", {
                settings = {
                    tailwindCSS = {
                        classAttributes = {
                            "class",
                            "className",
                            "class:list",
                            "classList",
                            "classNames",
                            "ngClass",
                        },
                        classFunctions = {
                            "clsx",
                            "cn",
                            "cva",
                            "cx",
                            "tw",
                            "twMerge",
                        },
                    },
                },
            })

            ----------------------------------------------------------------
            -- Emmet abbreviations in HTML, JSX/TSX, Vue, Svelte, and CSS
            ----------------------------------------------------------------

            vim.lsp.config("emmet_language_server", {
                init_options = {
                    -- Let nvim-cmp expand Emmet completion items as snippets.
                    showSuggestionsAsSnippets = true,
                },
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
