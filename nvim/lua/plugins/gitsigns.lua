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

                -- Stage and reset individual changes.
                map("<leader>hs", gs.stage_hunk, "Stage Git change")
                map("<leader>hr", gs.reset_hunk, "Reset Git change")

                -- Show the current line's Git history.
                map("<leader>hb", gs.blame_line, "Show Git blame")

                -- Show the file's Git diff.
                map("<leader>hd", gs.diffthis, "Show Git diff")
            end,
        },
    },
}
