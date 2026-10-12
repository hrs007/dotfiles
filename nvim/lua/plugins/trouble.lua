return {
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {
            -- Move focus into the Trouble list whenever it opens.
            focus = true,
            -- Keep list views visible even before quickfix or location lists
            -- have any entries, so these shortcuts still give clear feedback.
            open_no_results = true,
            win = {
                position = "bottom",
                size = 10,
                border = "rounded",
            },
        },
        keys = {
            {
                "<leader>xx",
                "<Cmd>Trouble diagnostics toggle<CR>",
                desc = "Diagnostics: Workspace",
            },
            {
                "<leader>xd",
                "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>",
                desc = "Diagnostics: Current file",
            },
            {
                "<leader>xq",
                "<Cmd>Trouble qflist toggle<CR>",
                desc = "Quickfix list",
            },
            {
                "<leader>xl",
                "<Cmd>Trouble loclist toggle<CR>",
                desc = "Location list",
            },
        },
    },
}
