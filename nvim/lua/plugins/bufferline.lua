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
                diagnostics = "nvim_lsp",
                diagnostics_update_in_insert = false,
                show_buffer_close_icons = false,
                show_close_icon = false,
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
            { "<S-l>", "<Cmd>BufferLineCycleNext<CR>", desc = "Buffer: Next" },
            { "<S-h>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Buffer: Previous" },
            { "<leader>bp", "<Cmd>BufferLinePick<CR>", desc = "Buffer: Pick" },
            { "<leader>bd", "<Cmd>bdelete<CR>", desc = "Buffer: Close" },
        },
    },
}
