return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {},
    },
    {
        "saghen/blink.cmp",
        version = "*",
        build = function()
            require("blink.cmp").build():pwait()
        end,
        dependencies = {
            "saghen/blink.lib",
            "rafamadriz/friendly-snippets",
            "giuxtaposition/blink-cmp-copilot",
        },
        opts = {
            keymap = {
                preset = "default",
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<CR>"] = { "accept", "fallback" },

                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },

                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                ["<C-f>"] = { "scroll_documentation_down", "fallback" },
            },

            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = "mono",
            },

            -- Use the native matcher where a compatible binary is available,
            -- and fall back to Lua on systems where it is not (including
            -- Windows setups without a supported prebuilt binary).
            fuzzy = {
                implementation = "prefer_rust_with_warning",
            },

            completion = {
                list = {
                    -- Leave suggestions unselected so Enter inserts a newline
                    -- unless the user explicitly chooses a completion item.
                    selection = {
                        preselect = false,
                        auto_insert = false,
                    },
                },
                accept = {
                    auto_brackets = {
                        enabled = true,
                    },
                },
                menu = {
                    border = "rounded",
                    draw = {
                        treesitter = { "lsp" },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 200,
                    window = {
                        border = "rounded",
                    },
                },
            },

            sources = {
                default = { "copilot", "lsp", "path", "snippets", "buffer" },
                providers = {
                    copilot = {
                        name = "copilot",
                        module = "blink-cmp-copilot",
                        score_offset = 100,
                        async = true,
                    },
                },
            },

            signature = {
                enabled = true,
                window = { border = "rounded" },
            },
        },
        opts_extend = { "sources.default" },
    },
}
