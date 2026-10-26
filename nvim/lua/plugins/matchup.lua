return {
    {
        -- Highlight and navigate between matching JSX/TSX tags.
        "andymass/vim-matchup",
        init = function()
            -- Make the tag pair stand out clearly while keeping cursor motion
            -- responsive in larger source files.
            vim.g.matchup_matchparen_deferred = 1
            vim.g.matchup_matchparen_offscreen = { method = "popup" }

            local function set_match_highlights()
                -- Use decoration without forcing foreground/background colors.
                -- This preserves Visual selection contrast, including on AMOLED.
                vim.api.nvim_set_hl(0, "MatchWord", { bold = true, underline = true })
                vim.api.nvim_set_hl(0, "MatchWordCur", { bold = true, underline = true })
            end

            set_match_highlights()
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("config.matchup_highlights", { clear = true }),
                callback = set_match_highlights,
                desc = "Keep matching JSX/TSX tags easy to see",
            })
        end,
        opts = {
            treesitter = {
                stopline = 500,
            },
        },
    },
}
