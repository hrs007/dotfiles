return {
    {
        "JoosepAlviste/nvim-ts-context-commentstring",
        lazy = true,
        opts = {
            enable_autocmd = false,
        },
        config = function(_, opts)
            require("ts_context_commentstring").setup(opts)

            -- Hook Tree-sitter commentstring calculation directly into
            -- Neovim 0.10+'s native commenting operator (gc / gcc).
            local get_option = vim.filetype.get_option
            vim.filetype.get_option = function(filetype, option)
                return option == "commentstring"
                    and require("ts_context_commentstring.internal").calculate_commentstring()
                    or get_option(filetype, option)
            end
        end,
    },
}
