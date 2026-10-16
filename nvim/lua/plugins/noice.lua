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
                -- Keep ordinary :echo/:messages output in the command area;
                -- reserve notification popups for vim.notify and warnings.
                view = "cmdline",
                view_error = "notify",
                view_warn = "notify",
                view_history = "messages",
            },
            notify = {
                enabled = true,
            },
            popupmenu = {
                enabled = true,
                backend = "nui",
            },
            lsp = {
                progress = {
                    -- Hide language-server progress popups such as "Finding
                    -- references" across all languages. LSP requests and
                    -- their results continue to work normally.
                    enabled = false,
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
            commands = {
                all = {
                    view = "split",
                    opts = { enter = true, format = "details" },
                },
            },
        },
        config = function(_, opts)
            -- Neovim 0.12 can send a lifecycle-only `restart` event to UI
            -- clients when a GUI attaches to an existing embedded instance.
            -- Noice expects widget events such as `msg_show` and errors while
            -- parsing `restart` as a widget name. Ignore that non-widget event
            -- so message, command-line, and popup UI keep working afterward.
            local ui = require("noice.ui")
            local get_handler = ui.get_handler
            ui.get_handler = function(event, ...)
                if type(event) ~= "string" or event == "restart" then
                    return
                end
                return get_handler(event, ...)
            end

            require("noice").setup(opts)

            vim.api.nvim_create_user_command("NotificationHistory", function()
                vim.cmd("Notifications")
            end, { desc = "Show popup notification history" })
            vim.api.nvim_create_user_command("MessageHistory", function()
                vim.cmd("Noice all")
            end, { desc = "Show all captured Neovim messages" })
        end,
        keys = {
            { "<leader>uh", "<Cmd>NotificationHistory<CR>", desc = "Notifications: History" },
            { "<leader>um", "<Cmd>MessageHistory<CR>", desc = "Messages: History" },
            { "<leader>ud", "<Cmd>Noice dismiss<CR>", desc = "Notifications: Dismiss" },
        },
    },
}
