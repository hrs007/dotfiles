return {
    {
        "lewis6991/gitsigns.nvim",

        event = { "BufReadPre", "BufNewFile" },

        opts = {
            -- Configure signs in the sign column.
            signs = {
                add = {
                    text = "+",
                },
                change = {
                    text = "~",
                },
                delete = {
                    text = "_",
                },
                topdelete = {
                    text = "‾",
                },
                changedelete = {
                    text = "~",
                },
            },

            -- Show the commit author and date for a line.
            current_line_blame = false,

            -- Configure Git-related keymaps.
            on_attach = function(bufnr)
                local gs = require("gitsigns")

                local function map(key, action, description)
                    vim.keymap.set("n", key, action, {
                        buffer = bufnr,
                        desc = description,
                    })
                end

                -- Navigate between changed sections.
                map("]c", function()
                    gs.nav_hunk("next")
                end, "Next Git change")

                map("[c", function()
                    gs.nav_hunk("prev")
                end, "Previous Git change")

                -- Preview changes.
                map("<leader>hp", gs.preview_hunk, "Preview Git change")

                -- Stage/unstage a hunk, or stage every change in this buffer.
                -- stage_hunk toggles staged hunks back out of the index too.
                map("<leader>hs", gs.stage_hunk, "Stage/unstage Git change")
                map("<leader>hu", gs.stage_hunk, "Unstage Git change")
                map("<leader>hS", gs.stage_buffer, "Stage all file changes")
                map("<leader>hr", gs.reset_hunk, "Reset Git change")

                -- Stage or reset only the selected lines of a changed hunk.
                vim.keymap.set("x", "<leader>hs", function()
                    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { buffer = bufnr, desc = "Stage selected Git lines" })
                vim.keymap.set("x", "<leader>hr", function()
                    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
                end, { buffer = bufnr, desc = "Reset selected Git lines" })

                -- Show the current line's Git history.
                map("<leader>hb", gs.blame_line, "Show Git blame")
                map("<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")

                -- Show the file's Git diff.
                map("<leader>hd", gs.diffthis, "Show Git diff")
            end,
        },
    },
}
