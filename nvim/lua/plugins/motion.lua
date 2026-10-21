-- Terminal Neovim cannot use Neovide's GPU animations. These plugins provide
-- a lightweight terminal approximation while Neovide keeps its native motion.
if vim.g.neovide then
    return {}
end

return {
    {
        "sphamba/smear-cursor.nvim",
        event = "VeryLazy",
        opts = {
            smear_between_buffers = true,
            smear_between_neighbor_lines = true,
            scroll_buffer_space = true,
            smear_insert_mode = true,
        },
    },
    {
        "karb94/neoscroll.nvim",
        event = "VeryLazy",
        opts = {
            mappings = {
                "<C-b>", "<C-f>",
                "<C-y>", "<C-e>",
                "zt", "zz", "zb",
            },
            hide_cursor = true,
            stop_eof = true,
            duration_multiplier = 0.8,
            easing = "sine",
        },
    },
}
