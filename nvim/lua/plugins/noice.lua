return {
    {
        "folke/noice.nvim",
        -- Match terminal Neovim's Noice UI when Neovide leaves these UI
        -- extensions available; skip it only when the GUI owns them already.
        enabled = not vim.g.neovide or vim.g.neovide_noice_compatible == true,
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
                -- Render the command line at the bottom edge, like Neovim's
                -- classic cmdline, instead of Noice's floating palette.
                view = "cmdline",
            },
            messages = {
                enabled = true,
                -- Keep ordinary Neovim messages, warnings, and errors as notifications.
                view = "notify",
                view_error = "notify",
                view_warn = "notify",
                view_history = "messages",
            },
            routes = {
                -- Register listings are command output, not transient notices.
                -- Show them in a floating pane while other
                -- notifications continue using the notification UI.
                {
                    view = "registers",
                    filter = {
                        event = "msg_show",
                        cmdline = "^:%s*reg",
                    },
                },
                -- Send other command output taller than three lines to a
                -- bottom split. vim.notify events are unaffected by this rule.
                {
                    view = "short_output",
                    filter = { event = "msg_show", min_height = 4, max_height = 9 },
                },
                {
                    view = "long_output",
                    filter = { event = "msg_show", min_height = 10 },
                },
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
                    silent = true,
                },
                signature = {
                    enabled = false,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = false,
                -- Output split sizing is handled by the routes below.
                long_message_to_split = false,
                lsp_doc_border = true,
            },
            views = {
                short_output = {
                    view = "split",
                    position = "bottom",
                    size = 8,
                    enter = true,
                },
                long_output = {
                    view = "split",
                    position = "bottom",
                    size = "35%",
                    enter = true,
                },
                -- Focus bottom splits when long command output opens so the
                -- user can close them with q or navigate from them normally.
                split = {
                    enter = true,
                },
                registers = {
                    backend = "popup",
                    relative = "editor",
                    position = "50%",
                    size = { width = "70%", height = "55%" },
                    enter = true,
                    border = { style = "rounded" },
                    close = { keys = { "q", "<Esc>" } },
                    win_options = { wrap = true, linebreak = true, cursorline = true },
                },
                -- Keep interactive prompts, including swap-file choices, at
                -- the bottom beside their question instead of the default
                -- top-positioned confirm popup.
                confirm = {
                    position = {
                        row = -3,
                        col = "50%",
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

            local function show_notification_history()
                local records = require("notify").history()
                local lines = {}
                for index = #records, 1, -1 do
                    local record = records[index]
                    local title = record.title and (record.title[1] or "") or ""
                    local level = (record.level or "INFO"):upper()
                    local timestamp = os.date("%H:%M:%S", record.time or os.time())
                    lines[#lines + 1] = ("%s  %-7s%s"):format(
                        timestamp,
                        level,
                        title ~= "" and ("· " .. title) or ""
                    )
                    for _, message_line in ipairs(record.message or {}) do
                        lines[#lines + 1] = "  " .. message_line
                    end
                    lines[#lines + 1] = ""
                end
                if #lines == 0 then lines[1] = "No notifications yet." end
                if lines[#lines] == "" then lines[#lines] = nil end

                local buffer = vim.fn.bufnr("Notifications")
                if buffer > 0 and vim.api.nvim_buf_is_valid(buffer) then
                    vim.bo[buffer].modifiable = true
                    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
                    vim.bo[buffer].modifiable = false
                    for _, window in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_buf(window) == buffer then
                            vim.api.nvim_set_current_win(window)
                            return
                        end
                    end
                else
                    buffer = vim.api.nvim_create_buf(false, true)
                    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
                    vim.bo[buffer].modifiable = false
                    vim.bo[buffer].bufhidden = "wipe"
                    vim.api.nvim_buf_set_name(buffer, "Notifications")
                    vim.bo[buffer].filetype = "notify-history"
                end
                vim.cmd("botright 8split")
                local window = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(window, buffer)
                vim.wo[window].wrap = true
                vim.wo[window].linebreak = true
                vim.wo[window].cursorline = true
                vim.wo[window].number = false
                vim.wo[window].relativenumber = false
                vim.wo[window].signcolumn = "no"
                local close = function()
                    if vim.api.nvim_win_is_valid(window) then vim.api.nvim_win_close(window, true) end
                end
                for _, key in ipairs({ "q", "<Esc>" }) do
                    vim.keymap.set("n", key, close, { buffer = buffer, nowait = true, silent = true })
                end
            end

            vim.api.nvim_create_user_command("NotificationHistory", function()
                show_notification_history()
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
