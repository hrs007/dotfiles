return {
    {
        "kdheepak/lazygit.nvim",
        cmd = { "LazyGit", "LazyGitCurrentFile" },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            { "<leader>gL", "<Cmd>LazyGit<CR>", desc = "Git: LazyGit" },
            { "<leader>gF", "<Cmd>LazyGitCurrentFile<CR>", desc = "Git: LazyGit current file" },
        },
    },
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
                stashes = { folded = false },
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
                    -- Reuse an existing Diffview tab instead of stacking a
                    -- new tab every time the shortcut is pressed.
                    local ok, lib = pcall(require, "diffview.lib")
                    if ok then
                        for _, view in ipairs(lib.views) do
                            if view.class.name == "DiffView" and view.tabpage
                                and vim.api.nvim_tabpage_is_valid(view.tabpage) then
                                vim.api.nvim_set_current_tabpage(view.tabpage)
                                return
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
            enhanced_diff_hl = true,
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
                    { "n", "g?", "<Cmd>lua require('diffview.actions').help({ 'view', 'diff2' })<CR>", { desc = "Show diff actions" } },
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
                    { "n", "g?", "<Cmd>lua require('diffview.actions').help('file_panel')<CR>", { desc = "Show file actions" } },
                },
                file_history_panel = {
                    { "n", "gf", false },
                    { "n", "<C-w>gf", false },
                },
            },
            view = {
                diff = {
                    -- Diffview's "horizontal" layout places the two versions
                    -- in side-by-side columns; "vertical" stacks them.
                    layout = "diff2_horizontal",
                },
                file_panel = {
                    win_config = {
                        width = 32,
                    },
                },
            },
        },
    },
}
