-- XML/XAML language-server actions. XAML buffers use the xml filetype.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "xml",
    callback = function(event)
        local opts = { buffer = event.buf, silent = true }

        vim.keymap.set("n", "<leader>lf", function()
            vim.lsp.buf.format({ bufnr = event.buf, async = false, timeout_ms = 5000 })
        end, vim.tbl_extend("force", opts, { desc = "Markup: Format XML/XAML" }))

        vim.keymap.set("n", "<leader>ls", function()
            require("telescope.builtin").lsp_document_symbols()
        end, vim.tbl_extend("force", opts, { desc = "Markup: Find XML/XAML symbols" }))

        vim.keymap.set("n", "<leader>ld", function()
            vim.diagnostic.open_float(event.buf)
        end, vim.tbl_extend("force", opts, { desc = "Markup: Show XML/XAML diagnostic" }))
    end,
})
