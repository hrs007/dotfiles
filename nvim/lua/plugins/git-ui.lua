-- Keep the interactive swap prompt active when Lazy reloads this spec.
require("config.swapfile").setup()

local function jump_diff_hunk(direction)
    local current_row = vim.api.nvim_win_get_cursor(0)[1]
    local forward = direction == "]c"
    vim.cmd("silent! normal! " .. direction)

    if vim.api.nvim_win_get_cursor(0)[1] ~= current_row then
        return
    end

    local last_row = vim.api.nvim_buf_line_count(0)
    local edge_row = forward and 1 or last_row
    vim.api.nvim_win_set_cursor(0, { edge_row, 0 })

    -- If the first/last line is itself part of a hunk, stop there; otherwise
    -- let Vim find the nearest hunk from the opposite edge.
    if vim.fn.diff_hlID(edge_row, 1) == 0 then
        vim.cmd("silent! normal! " .. direction)
    end
end

return {
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            "sindrets/diffview.nvim",
        },
        opts = {
            kind = "tab",
            floating = {
                border = "rounded",
            },
            integrations = {
                telescope = true,
                diffview = true,
            },
            sections = {
                recent = { folded = true },
                stashes = { folded = true },
                unpulled_upstream = { folded = true },
                unpulled_pushRemote = { folded = true },
            },
            status = {
                -- Keep the branch and working-tree sections prominent without
                -- spending header space on a commit hash on every refresh.
                show_head_commit_hash = false,
                recent_commit_count = 5,
            },
            signs = {
                section = { "▸", "▾" },
                item = { "›", "›" },
            },
        },
        keys = {
            { "<leader>gg", "<Cmd>Neogit kind=tab<CR>", desc = "Git: Status" },
            { "<leader>gc", "<Cmd>Neogit commit<CR>", desc = "Git: Commit" },
            { "<leader>gp", "<Cmd>Neogit push<CR>", desc = "Git: Push" },
            { "<leader>gP", "<Cmd>Neogit pull<CR>", desc = "Git: Pull" },
            { "<leader>gs", "<Cmd>Neogit stash<CR>", desc = "Git: Stashes" },
            { "<leader>gl", "<Cmd>Neogit log<CR>", desc = "Git: Log" },
            {
                "<leader>gd",
                function()
                    -- Rebuild an existing view so it picks up changed diff
                    -- options and highlight settings instead of keeping stale
                    -- window-local diff state.
                    local ok, lib = pcall(require, "diffview.lib")
                    if ok then
                        for _, view in ipairs(lib.views) do
                            if view.class.name == "DiffView" and view.tabpage
                                and vim.api.nvim_tabpage_is_valid(view.tabpage) then
                                vim.api.nvim_set_current_tabpage(view.tabpage)
                                require("diffview").close()
                                break
                            end
                        end
                    end
                    vim.cmd("DiffviewOpen")
                end,
                desc = "Git: Review changes",
            },
            { "<leader>gh", "<Cmd>DiffviewFileHistory %<CR>", desc = "Git: File history" },
            { "<leader>gH", "<Cmd>DiffviewFileHistory<CR>", desc = "Git: Repository history" },
        },
    },
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewFileHistory" },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            -- Use the standard DiffAdd/DiffDelete colors so real changed
            -- lines are easy to distinguish from unchanged context.
            enhanced_diff_hl = false,
            keymaps = {
                view = {
                    {
                        "n",
                        "q",
                        function()
                            require("diffview").close()
                        end,
                        { desc = "Close Diffview" },
                    },
                    { "n", "gf", false },
                    { "n", "<C-w>gf", false },
                    { "n", "s", "<Cmd>lua require('diffview.actions').toggle_stage_entry()<CR>", { desc = "Stage / unstage this file" } },
                    { "n", "S", "<Cmd>lua require('diffview.actions').stage_all()<CR>", { desc = "Stage all changes" } },
                    { "n", "u", "<Cmd>lua require('diffview.actions').unstage_all()<CR>", { desc = "Unstage all changes" } },
                    {
                        "n",
                        "X",
                        function()
                            vim.ui.select({ "Discard this file's changes", "Cancel" }, {
                                prompt = "Discard all changes in this file?",
                            }, function(choice)
                                if choice == "Discard this file's changes" then
                                    require("diffview.actions").restore_entry()
                                end
                            end)
                        end,
                        { desc = "Discard this file's changes (confirm)" },
                    },
                    {
                        "n",
                        "g?",
                        function() require("diffview.actions").help({ "view", "diff2" })() end,
                        { desc = "Open the help panel" },
                    },
                    { "n", "R", "<Cmd>lua require('diffview.actions').refresh_files()<CR>", { desc = "Refresh changed files" } },
                },
                file_panel = {
                    {
                        "n",
                        "q",
                        function()
                            require("diffview").close()
                        end,
                        { desc = "Close Diffview" },
                    },
                    { "n", "gf", false },
                    { "n", "<C-w>gf", false },
                    { "n", "s", "<Cmd>lua require('diffview.actions').toggle_stage_entry()<CR>", { desc = "Stage / unstage this file" } },
                    { "n", "S", "<Cmd>lua require('diffview.actions').stage_all()<CR>", { desc = "Stage all files" } },
                    { "n", "u", "<Cmd>lua require('diffview.actions').unstage_all()<CR>", { desc = "Unstage all files" } },
                    {
                        "n",
                        "X",
                        function()
                            vim.ui.select({ "Discard this file's changes", "Cancel" }, {
                                prompt = "Discard selected file changes?",
                            }, function(choice)
                                if choice == "Discard this file's changes" then
                                    require("diffview.actions").restore_entry()
                                end
                            end)
                        end,
                        { desc = "Discard this file's changes (confirm)" },
                    },
                    {
                        "n",
                        "g?",
                        function() require("diffview.actions").help("file_panel")() end,
                        { desc = "Open the help panel" },
                    },
                    { "n", "R", "<Cmd>lua require('diffview.actions').refresh_files()<CR>", { desc = "Refresh changed files" } },
                },
                file_history_panel = {
                    { "n", "gf", false },
                    { "n", "<C-w>gf", false },
                },
            },
            view = {
                default = {
                    -- Show Diffview's INDEX / WORKING TREE label above each
                    -- side so the source of each version is obvious.
                    winbar_info = true,
                },
                diff = {
                    -- Diffview's "horizontal" layout places the two versions
                    -- in side-by-side columns; "vertical" stacks them.
                    layout = "diff2_horizontal",
                },
                file_panel = {
                    win_config = function()
                        return {
                            position = "left",
                            width = math.min(42, math.max(30, math.floor(vim.o.columns * 0.24))),
                            win_opts = {
                                cursorline = true,
                                foldcolumn = "0",
                                number = false,
                                relativenumber = false,
                                signcolumn = "no",
                                wrap = false,
                                winbar = "  + Add   - Del   s Stage",
                            },
                        }
                    end,
                },
            },
            hooks = {
                diff_buf_read = function()
                    vim.opt_local.wrap = false
                    vim.opt_local.number = true
                    vim.opt_local.relativenumber = false
                    vim.opt_local.signcolumn = "no"
                    vim.opt_local.foldcolumn = "0"
                    -- Diffview creates diff folds at level 0 by default,
                    -- hiding unchanged code when the pane opens. Start open
                    -- while keeping normal fold controls available.
                    vim.opt_local.foldlevel = 99
                    vim.opt_local.scrolloff = 4
                    vim.opt_local.sidescrolloff = 4

                    -- Gitsigns also maps these keys on working-tree buffers;
                    -- Diffview panes should navigate their displayed diff.
                    vim.keymap.set("n", "]c", function()
                        jump_diff_hunk("]c")
                    end, { buffer = 0, silent = true, desc = "Next diff hunk (wrap)" })
                    vim.keymap.set("n", "[c", function()
                        jump_diff_hunk("[c")
                    end, { buffer = 0, silent = true, desc = "Previous diff hunk (wrap)" })

                    local function set_diff_foldlevel(level)
                        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                            if vim.wo[winid].diff then
                                vim.wo[winid].foldenable = true
                                vim.wo[winid].foldlevel = level
                            end
                        end
                    end
                    vim.keymap.set("n", "zR", function()
                        set_diff_foldlevel(99)
                    end, { buffer = 0, silent = true, desc = "Open all diff folds" })
                    vim.keymap.set("n", "zM", function()
                        set_diff_foldlevel(0)
                    end, { buffer = 0, silent = true, desc = "Close all diff folds" })
                end,
                diff_buf_win_enter = function(_, winid)
                    -- Diffview reapplies foldlevel=0 when changing files;
                    -- reset it after the window is entered so code stays open.
                    vim.wo[winid].foldenable = true
                    vim.wo[winid].foldlevel = 99
                end,
            },
        },
    },
}
