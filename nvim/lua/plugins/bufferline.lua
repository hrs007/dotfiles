return {
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        event = "VeryLazy",
        opts = {
            options = {
                mode = "buffers",
                numbers = "ordinal",
                show_buffer_icons = false,
                show_buffer_close_icons = false,
                show_close_icon = false,
                diagnostics = "nvim_lsp",
                diagnostics_update_in_insert = false,
                separator_style = "thin",
                always_show_bufferline = false,
                offsets = {
                    {
                        filetype = "oil",
                        text = "File Explorer",
                        text_align = "center",
                        separator = true,
                    },
                },
            },
        },
        keys = {
            { "Q", "<Cmd>bdelete<CR>", desc = "Buffer: Close current" },
            { "<S-l>", "<Cmd>BufferLineCycleNext<CR>", desc = "Buffer: Next" },
            { "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Buffer: Previous" },
            { "<leader>vn", "<Cmd>enew<CR>", desc = "Buffer: New empty" },
            { "<leader>vh", "<Cmd>BufferLineCyclePrev<CR>", desc = "Buffer: Previous" },
            { "<leader>vl", "<Cmd>BufferLineCycleNext<CR>", desc = "Buffer: Next" },
            { "<leader>vH", "<Cmd>BufferLineMovePrev<CR>", desc = "Buffer: Move left" },
            { "<leader>vL", "<Cmd>BufferLineMoveNext<CR>", desc = "Buffer: Move right" },
            { "<leader>vp", "<Cmd>BufferLinePick<CR>", desc = "Buffer: Pick" },
            { "<leader>vd", "<Cmd>bdelete<CR>", desc = "Buffer: Close" },
        },
    },
}
