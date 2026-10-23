return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            -- Avoid signs for end-of-line whitespace-only differences.
            diff_opts = {
                ignore_whitespace_change_at_eol = true,
            },
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
                untracked = { text = "┆" },
            },
            signs_staged_enable = true,
            current_line_blame = false,
            on_attach = function(bufnr)
                local gs = require("gitsigns")
                local function map(mode, lhs, rhs, description)
                    vim.keymap.set(mode, lhs, rhs, {
                        buffer = bufnr,
                        silent = true,
                        desc = description,
                    })
                end

                map("n", "]c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ args = { "]c" }, bang = true })
                    else
                        gs.nav_hunk("next")
                    end
                end, "Next Git hunk")
                map("n", "[c", function()
                    if vim.wo.diff then
                        vim.cmd.normal({ args = { "[c" }, bang = true })
                    else
                        gs.nav_hunk("prev")
                    end
                end, "Previous Git hunk")
                map("n", "<leader>hp", gs.preview_hunk, "Preview Git hunk")
                map("n", "<leader>hs", gs.stage_hunk, "Stage Git hunk")
                map("n", "<leader>hr", gs.reset_hunk, "Discard Git hunk")
                map("n", "<leader>hS", gs.stage_buffer, "Stage all file changes")
                map("n", "<leader>hR", gs.reset_buffer, "Discard file changes")
                map("n", "<leader>hc", function()
                    local hunks = gs.get_hunks(bufnr) or {}
                    vim.notify(("%d unstaged Git hunk%s in this file"):format(#hunks, #hunks == 1 and "" or "s"))
                end, "Count unstaged Git hunks")
                map("n", "<leader>hq", function() gs.setqflist("all") end, "List Git hunks in quickfix")
                map("n", "<leader>hd", gs.diffthis, "Diff file with Git index")
                map("n", "<leader>hD", function() gs.diffthis(nil, { unified = true }) end, "Unified Git diff")
                map("n", "<leader>gd", "<Cmd>Gitsigns diff<CR>", "Open Gitsigns diff view")
                map("n", "<leader>ht", function()
                    local enabled = gs.toggle_signs()
                    vim.notify("Git signs " .. (enabled and "enabled" or "disabled"))
                end, "Toggle Git signs")
                map("n", "<leader>hn", function()
                    local enabled = gs.toggle_numhl()
                    vim.notify("Git number highlights " .. (enabled and "enabled" or "disabled"))
                end, "Toggle Git number highlights")
                map("n", "<leader>hl", function()
                    local enabled = gs.toggle_linehl()
                    vim.notify("Git line highlights " .. (enabled and "enabled" or "disabled"))
                end, "Toggle Git line highlights")
                map("n", "<leader>hw", function()
                    local enabled = gs.toggle_word_diff()
                    vim.notify("Git word diff " .. (enabled and "enabled" or "disabled"))
                end, "Toggle Git word diff")
                map("n", "<leader>hb", gs.blame_line, "Show line blame")
                map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle current-line blame")

                map("x", "<leader>hs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, "Stage selected Git lines")
            end,
        },
        config = function(_, opts)
            -- Guard Gitsigns' unified diff preview against inline ranges that
            -- exceed the displayed row or split a UTF-8 character.
            require("config.gitsigns_preview").setup()
            require("gitsigns").setup(opts)
        end,
    },
}
