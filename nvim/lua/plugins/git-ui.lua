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

local diff_hunk_maps = vim.api.nvim_create_augroup("GitDiffHunkMaps", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
    group = diff_hunk_maps,
    callback = function(event)
        if not vim.wo.diff then return end

        local bufnr = event.buf
        for _, direction in ipairs({ "]c", "[c" }) do
            local key = direction
            vim.keymap.set("n", key, function()
                if vim.wo.diff then
                    jump_diff_hunk(key)
                    return
                end

                -- Preserve Gitsigns navigation if this buffer is later shown
                -- outside a diff window.
                local ok, gitsigns = pcall(require, "gitsigns")
                if ok then
                    gitsigns.nav_hunk(key == "]c" and "next" or "prev", { target = "all" })
                else
                    vim.cmd("normal! " .. key)
                end
            end, {
                buffer = bufnr,
                silent = true,
                desc = key == "]c" and "Next diff hunk" or "Previous diff hunk",
            })
        end
    end,
    desc = "Use diff hunk navigation in Git diff windows",
})

local function refresh_current_diffview_file()
    local tabpage = vim.api.nvim_get_current_tabpage()
    local ok, lib = pcall(require, "diffview.lib")
    if not ok then return end

    for _, view in ipairs(lib.views) do
        if view.tabpage == tabpage and view.cur_entry and view.cur_layout then
            -- Diffview's normal index-stat refresh can keep valid LOCAL and
            -- STAGE buffers alive. After an index mutation, force those
            -- backing buffers to be recreated or the panes can show a full
            -- file as DiffAdd/DiffDelete.
            view.cur_layout:detach_files()
            for _, file in ipairs(view.cur_entry.layout:files()) do
                file:dispose_buffer()
            end
            view.update_needed = true
            view:update_files()
            return
        end
    end
end

local function find_git_diff_hunk(adapter, path, row, use_cached, old_side)
    local args = { "git", "diff", "--no-ext-diff", "--no-color", "--unified=3" }
    if use_cached then table.insert(args, "--cached") end
    table.insert(args, "--")
    table.insert(args, path)

    local result = vim.system(args, { cwd = adapter.ctx.toplevel, text = true }):wait()
    if result.code ~= 0 or not result.stdout or result.stdout == "" then
        return nil, result.stderr or "No Git diff is available for this file."
    end

    local lines = vim.split(result.stdout, "\n", { plain = true })
    local header, hunk_start = {}, nil
    for i, line in ipairs(lines) do
        if line:match("^@@ ") then
            hunk_start = i
            break
        end
        if line:match("^diff %-%-git ") or #header > 0 then
            table.insert(header, line)
        end
    end
    if not hunk_start then return nil, "No Git hunk is available at this file." end

    local i = hunk_start
    while i <= #lines do
        local hunk_header = lines[i]
        if not hunk_header:match("^@@ ") then i = i + 1 goto continue end
        local old_start, old_count, new_start, new_count = hunk_header:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
        old_start, new_start = tonumber(old_start), tonumber(new_start)
        old_count = old_count == "" and 1 or tonumber(old_count)
        new_count = new_count == "" and 1 or tonumber(new_count)
        local side_start, side_count = old_side and old_start or new_start, old_side and old_count or new_count
        local contains = side_count == 0 and (row == side_start or row == side_start + 1)
            or side_count > 0 and row >= side_start and row <= side_start + side_count - 1
        local finish = i + 1
        while finish <= #lines and not lines[finish]:match("^@@ ") and not lines[finish]:match("^diff %-%-git ") do
            finish = finish + 1
        end
        if contains then
            local patch_lines = vim.list_extend(vim.deepcopy(header), vim.list_slice(lines, i, finish - 1))
            return table.concat(patch_lines, "\n") .. "\n"
        end
        i = finish
        ::continue::
    end
    return nil, "No Git hunk found at the cursor."
end

local function diffview_hunk_action(stage)
    local ok, lib = pcall(require, "diffview.lib")
    if not ok then return end
    local current_win = vim.api.nvim_get_current_win()
    for _, view in ipairs(lib.views) do
        if view.tabpage == vim.api.nvim_get_current_tabpage() and view.cur_entry and view.cur_layout then
            local left, right = view.cur_layout.a, view.cur_layout.b
            if not left or not right or not left:is_valid() or not right:is_valid()
                or (current_win ~= left.id and current_win ~= right.id) then goto continue end

            local RevType = require("diffview.vcs.rev").RevType
            local left_rev, right_rev = left.file.rev, right.file.rev
            local is_working = left_rev.type == RevType.STAGE and left_rev.stage == 0 and right_rev.type == RevType.LOCAL
            local is_staged = left_rev.type == RevType.COMMIT and right_rev.type == RevType.STAGE and right_rev.stage == 0
            if (stage and not is_working) or (not stage and not is_staged) then
                vim.notify(stage and "Use s in a working-tree diff to stage a hunk." or "Use u in a staged diff to unstage a hunk.", vim.log.levels.INFO)
                return
            end

            local old_side = current_win == left.id
            local row = vim.api.nvim_win_get_cursor(current_win)[1]
            local patch, err = find_git_diff_hunk(view.adapter, view.cur_entry.path, row, not stage, old_side)
            if not patch then
                vim.notify(err, vim.log.levels.INFO)
                return
            end

            local command = {
                "git", "apply", "--cached", "--recount",
                "--ignore-space-change", "--ignore-whitespace",
                "--whitespace=nowarn",
            }
            if not stage then table.insert(command, "--reverse") end
            local result = vim.system(command, {
                cwd = view.adapter.ctx.toplevel,
                stdin = patch,
                text = true,
            }):wait()
            if result.code ~= 0 then
                vim.notify(vim.trim(result.stderr or "Git could not apply the selected hunk."), vim.log.levels.ERROR)
                return
            end
            view:update_files()
            return
        end
        ::continue::
    end
    vim.notify("No active Diffview file pane found.", vim.log.levels.WARN)
end

local function patch_diffview_index_cache()
    local file_entry = require("diffview.scene.file_entry").FileEntry
    if file_entry.__index_cache_precision_fix then return end

    local update_index_stat = file_entry.update_index_stat
    file_entry.update_index_stat = function(adapter, stat)
        if stat and stat.mtime and stat.mtime.sec then
            -- Diffview caches index mtimes at one-second precision. Keep its
            -- cache one second behind so fast stage/unstage operations still
            -- trigger blob-hash validation and invalidate changed index panes.
            stat = vim.deepcopy(stat)
            stat.mtime.sec = stat.mtime.sec - 1
        end
        return update_index_stat(adapter, stat)
    end
    file_entry.__index_cache_precision_fix = true
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
            mappings = {
                status = {
                    ["]c"] = "GoToNextHunkHeader",
                    ["[c"] = "GoToPreviousHunkHeader",
                },
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
                    { "n", "s", function() diffview_hunk_action(true) end, { desc = "Stage this hunk" } },
                    { "n", "u", function() diffview_hunk_action(false) end, { desc = "Unstage this hunk" } },
                    { "n", "S", "<Cmd>lua require('diffview.actions').stage_all()<CR>", { desc = "Stage all changes" } },
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
                    { "n", "R", function() refresh_current_diffview_file() end, { desc = "Refresh changed files and diff panes" } },
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
                    { "n", "R", function() refresh_current_diffview_file() end, { desc = "Refresh changed files and diff panes" } },
                },
                file_history_panel = {
                    { "n", "gf", false },
                    { "n", "<C-w>gf", false },
                },
            },
            view = {
                default = {
                    -- Show the source/version title above each diff pane.
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
                diff_buf_read = function(bufnr)
                    -- Git index snapshots are immutable from the editor.
                    -- Hunk staging uses `git apply --cached` instead of
                    -- editing these virtual buffers.
                    local ok, lib = pcall(require, "diffview.lib")
                    if ok then
                        for _, view in ipairs(lib.views) do
                            for _, entry in view.files:iter() do
                                for _, file in ipairs(entry.layout:files()) do
                                    local rev = file.rev
                                    if file.bufnr == bufnr and rev.type == require("diffview.vcs.rev").RevType.STAGE
                                        and rev.stage == 0 then
                                        vim.bo[bufnr].modifiable = false
                                        vim.bo[bufnr].readonly = true
                                    end
                                end
                            end
                        end
                    end

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
        config = function(_, opts)
            require("diffview").setup(opts)
            patch_diffview_index_cache()
        end,
    },
}
