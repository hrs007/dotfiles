-- Configure how diagnostics appear in Neovim.
vim.diagnostic.config({
    -- Show diagnostic signs in the sign column.
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },

    -- Keep diagnostics visible both in the sign column and under affected text.
    underline = true,
    virtual_text = false,

    -- Update diagnostics after leaving Insert mode.
    update_in_insert = false,

    -- Sort errors before warnings, then other diagnostics.
    severity_sort = true,

    float = {
        border = "rounded",
        source = true,
        header = "Diagnostics",
        prefix = "",
    },
})
