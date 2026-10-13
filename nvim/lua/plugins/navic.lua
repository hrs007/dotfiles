return {
    {
        "SmiteshP/nvim-navic",
        lazy = false,
        opts = {
            highlight = true,
            separator = " › ",
            depth_limit = 4,
            depth_limit_indicator = "…",
            safe_output = true,
            lsp = {
                auto_attach = true,
            },
        },
    },
}
