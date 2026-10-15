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
                if vim.tbl_contains(installed, lang) then
                    return false
                end
                -- Neovim ships a small set of parsers itself. Do not try to
                -- rebuild those on every startup just because they are outside
                -- nvim-treesitter's install directory.
                return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", true) == 0
            end, ensure_installed)

            if #to_install > 0 then
                -- On Windows, Vim's executable() expects the .exe suffix for
                -- MSVC's compiler (cl alone is not detected reliably).
                local has_compiler = vim.iter({ "cl.exe", "clang", "gcc" }):any(function(compiler)
                    return vim.fn.executable(compiler) == 1
                end)
                local has_requirements = vim.fn.executable("tree-sitter") == 1
                    and has_compiler
                    and vim.fn.executable("tar") == 1
                    and vim.fn.executable("curl") == 1

                if has_requirements then
                    ts.install(to_install)
                else
                    vim.notify(
                        "Tree-sitter parsers are missing. Install tree-sitter-cli 0.26.1+ and a C compiler, then restart Neovim.",
                        vim.log.levels.WARN
                    )
                end
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
