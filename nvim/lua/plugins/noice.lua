return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            {
                "rcarriga/nvim-notify",
                opts = {
                    render = "compact",
                    max_width = 52,
                    max_height = 4,
                    timeout = 2500,
                    stages = "fade_in_slide_out",
                },
            },
        },
        opts = {
            cmdline = {
                enabled = true,
                view = "cmdline_popup",
            },
            messages = {
                enabled = true,
            },
            notify = {
                enabled = true,
            },
            -- Align command-line completions with the command palette.
            -- nvim-cmp keeps its own separate code-completion window.
            popupmenu = {
                enabled = true,
                backend = "cmp",
            },
            lsp = {
                progress = {
                    enabled = true,
                },
                hover = {
                    enabled = true,
                },
                signature = {
                    enabled = false,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                lsp_doc_border = true,
            },
            views = {
                cmdline_popup = {
                    border = {
                        style = "rounded",
                    },
                },
            },
        },
        keys = {
            { "<leader>nh", "<Cmd>Noice history<CR>", desc = "UI: Message history" },
            { "<leader>nd", "<Cmd>Noice dismiss<CR>", desc = "UI: Dismiss notifications" },
        },
    },
}
