return {
    {
        -- Parse source code and provide Tree-sitter queries.
        "nvim-treesitter/nvim-treesitter",

        -- Tree-sitter must be loaded during startup.
        lazy = false,

        -- Update parsers when installing or updating the plugin.
        build = ":TSUpdate",

        config = function()
            -- Configure Tree-sitter's parser installation directory.
            require("nvim-treesitter").setup({
                install_dir = vim.fn.stdpath("data") .. "/site",
            })

            -- Enable Tree-sitter highlighting for supported filetypes.
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    -- Start highlighting for the current buffer.
                    -- pcall prevents unsupported filetypes from causing errors.
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },
}
