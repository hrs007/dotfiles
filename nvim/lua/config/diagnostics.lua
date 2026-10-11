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

    -- Underline problematic code.
    underline = true,

    -- Show diagnostics in the editor.
    virtual_text = {
        spacing = 2,
        prefix = "●",
        source = "if_many",
    },

    -- Show diagnostic information when the cursor stops moving.
    update_in_insert = false,

    -- Sort errors before warnings, then other diagnostics.
    severity_sort = true,

    -- Configure floating diagnostic windows.
    float = {
        border = "rounded",
        source = true,
        header = "Diagnostics",
        prefix = "",
    },
})

-- Automatically show diagnostic details when the cursor stops.
vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        vim.diagnostic.open_float(nil, {
            focus = false,
            scope = "cursor",
            border = "rounded",
        })
    end,
})
