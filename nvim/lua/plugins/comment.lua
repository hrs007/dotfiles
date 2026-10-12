return {
    {
        "numToStr/Comment.nvim",
        event = "VeryLazy",
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring",
        },
        opts = function()
            return {
                -- Choose // versus JSX/HTML comment syntax from the current
                -- Tree-sitter context, including mixed TSX files.
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            }
        end,
    },
}
