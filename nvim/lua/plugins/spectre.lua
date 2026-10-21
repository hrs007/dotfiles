return {
    {
        "nvim-pack/nvim-spectre",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = "Spectre",
        config = function(_, opts)
            require("spectre").setup(opts)
        end,
        keys = {
            {
                "<leader>fR",
                function()
                    require("spectre").open({ cwd = require("config.project").current_dir() })
                end,
                desc = "Search and replace in project",
            },
            {
                "<leader>fr",
                function() require("spectre").open_file_search() end,
                desc = "Search and replace in file",
            },
            {
                "<leader>fW",
                function()
                    require("spectre").open_visual({
                        select_word = true,
                        cwd = require("config.project").current_dir(),
                    })
                end,
                desc = "Replace word in project",
            },
            {
                "<leader>fW",
                "<Esc><Cmd>lua require('spectre').open_visual()<CR>",
                mode = "v",
                desc = "Replace selection in project",
            },
        },
        opts = {
            -- Prevent the search panel from being visually damaged by window
            -- resize and redraw events.
            is_block_ui_break = true,
            mapping = {
                close_panel = {
                    map = "q",
                    cmd = "<cmd>lua require('spectre').close()<CR>",
                    desc = "close search panel",
                },
                close_panel_escape = {
                    map = "<Esc>",
                    cmd = "<cmd>lua require('spectre').close()<CR>",
                    desc = "close search panel",
                },
                change_view = {
                    map = "<leader>v",
                    cmd = "<cmd>lua (function() local state = require('spectre.state'); if state.is_open and type(state.bufnr) == 'number' and vim.api.nvim_buf_is_valid(state.bufnr) then require('spectre').change_view() end end)()<CR>",
                    desc = "toggle search and replace view",
                },
            },
        },
    },
}
