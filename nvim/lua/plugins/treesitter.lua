return {
    {
        -- Parse source code and provide Tree-sitter queries.
        "nvim-treesitter/nvim-treesitter",

        -- Tree-sitter must be loaded during startup.
        lazy = false,

        -- Update parsers when installing or updating the plugin.
        build = ":TSUpdate",
        dependencies = {
            "windwp/nvim-ts-autotag",
        },

        config = function()
            local ts = require("nvim-treesitter")

            -- Configure Tree-sitter's parser installation directory.
            ts.setup({
                install_dir = vim.fn.stdpath("data") .. "/site",
            })

            -- Ensure core parsers are installed.
            local ensure_installed = {
                "lua",
                "vim",
                "vimdoc",
                "python",
                "javascript",
                "typescript",
                "tsx",
                "html",
                "css",
                "c",
                "cpp",
                "c_sharp",
                "json",
                "yaml",
                "xml",
                "markdown",
                "markdown_inline",
                "bash",
                "diff",
            }

            local installed = ts.get_installed()
            local to_install = vim.tbl_filter(function(lang)
                return not vim.tbl_contains(installed, lang)
            end, ensure_installed)

            if #to_install > 0 then
                ts.install(to_install)
            end

            -- Close matching HTML/JSX tags and rename their pairs together.
            require("nvim-ts-autotag").setup()

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
