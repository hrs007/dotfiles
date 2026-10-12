return {
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",

        dependencies = {
            "windwp/nvim-autopairs",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },

        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            -- Automatically insert matching delimiters in code buffers,
            -- including TypeScript React (TSX) files.
            require("nvim-autopairs").setup({})

            -- Load community snippet collections.
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                window = {
                    completion = {
                        border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                        scrollbar = false,
                        max_width = 60,
                    },
                    documentation = {
                        border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                        max_width = 60,
                    },
                },

                -- Tell Neovim how to expand snippets.
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                completion = {
                    completeopt = "menu,menuone,noselect",
                },
                preselect = cmp.PreselectMode.None,

                formatting = {
                    format = function(entry, item)
                        if entry.source.name == "copilot" then
                            item.kind = "Copilot"
                            item.menu = "[AI]"
                        end
                        return item
                    end,
                },

                -- Keyboard controls.
                mapping = cmp.mapping.preset.insert({
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),

                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),

                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),

                    ["<CR>"] = cmp.mapping(function(fallback)
                        if cmp.visible() and cmp.get_selected_entry() then
                            cmp.confirm({ select = false })
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),

                -- Where suggestions come from.
                sources = cmp.config.sources({
                    { name = "copilot", priority = 100 },
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "path" },
                }, {
                    { name = "buffer" },
                }),
            })

            -- Show command and path completions as the user types after `:`.
            cmp.setup.cmdline(":", {
                completion = {
                    autocomplete = { cmp.TriggerEvent.TextChanged },
                },
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    {
                        name = "cmdline",
                        option = { ignore_cmds = { "Man", "!" } },
                    },
                }),
                matching = { disallow_symbol_nonprefix_matching = false },
            })

            -- Suggest matching words automatically for `/` and `?` searches.
            cmp.setup.cmdline({ "/", "?" }, {
                completion = {
                    autocomplete = { cmp.TriggerEvent.TextChanged },
                },
                mapping = cmp.mapping.preset.cmdline(),
                sources = { { name = "buffer" } },
            })

            -- Add a closing delimiter when accepting a completion that ends
            -- with an opening delimiter, such as a function call.
            cmp.event:on(
                "confirm_done",
                require("nvim-autopairs.completion.cmp").on_confirm_done()
            )
        end,
    },
}
