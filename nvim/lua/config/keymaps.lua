-- Create a local reference to Neovim's keymap function.
-- This avoids repeatedly writing vim.keymap.set.
local map = vim.keymap.set


-- ==========================================
-- Leader Keys
-- ==========================================

-- Use Space as the prefix for custom keyboard shortcuts.
-- For example, Space followed by w will save the file.
vim.g.mapleader = " "

-- Set the local leader key to Space as well.
-- This is useful for filetype-specific mappings later.
vim.g.maplocalleader = " "


-- ==========================================
-- Search Highlighting
-- ==========================================

-- Press Escape in Normal mode to clear search highlighting.
-- The mapping also leaves the cursor in Normal mode.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
    desc = "Clear search highlighting",
})


-- ==========================================
-- Search Navigation
-- ==========================================

-- Move to the next search result and center it vertically.
-- zzzv centers the cursor and opens folds around it.
map("n", "n", "nzzzv", {
    desc = "Next search result centered",
})

-- Move to the previous search result and center it vertically.
map("n", "N", "Nzzzv", {
    desc = "Previous search result centered",
})


-- ==========================================
-- Scrolling
-- ==========================================

-- Scroll down half a screen and center the cursor afterward.
map("n", "<C-d>", "<C-d>zz", {
    desc = "Scroll down and center",
})

-- Scroll up half a screen and center the cursor afterward.
map("n", "<C-u>", "<C-u>zz", {
    desc = "Scroll up and center",
})


-- ==========================================
-- Saving
-- ==========================================

-- Press Space followed by w to save the current file.
map("n", "<leader>w", "<cmd>write<CR>", {
    desc = "Save file",
})


-- ==========================================
-- Quitting
-- ==========================================

-- Press Space followed by q to quit the current window.
-- Neovim will not silently discard unsaved changes.
map("n", "<leader>q", "<cmd>quit<CR>", {
    desc = "Quit window",
})


-- ==========================================
-- Window Navigation
-- ==========================================

-- Move to the window on the left.
map("n", "<C-h>", "<C-w>h", {
    desc = "Move to left window",
})

-- Move to the window below.
map("n", "<C-j>", "<C-w>j", {
    desc = "Move to lower window",
})

-- Move to the window above.
map("n", "<C-k>", "<C-w>k", {
    desc = "Move to upper window",
})

-- Move to the window on the right.
map("n", "<C-l>", "<C-w>l", {
    desc = "Move to right window",
})


-- Set up keymaps when an LSP attaches to a buffer.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        -- Only apply these mappings to the current buffer.
        local opts = { buffer = event.buf, silent = true }

        -- Go to the definition of a symbol.
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

        -- Find references to a symbol.
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

        -- Show documentation and type information.
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

        -- Rename a symbol.
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        -- Show available code actions.
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

        -- Jump to the previous diagnostic.
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

        -- Jump to the next diagnostic.
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

        -- Display the diagnostic under the cursor.
        vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
    end,
})

-- Terminal integration

-- Open a terminal in a horizontal split
vim.keymap.set("n", "<leader>th", function()
    vim.cmd("botright 12split | terminal")
end, { desc = "Terminal: Horizontal" })

-- Open a terminal in a vertical split
vim.keymap.set("n", "<leader>tv", function()
    vim.cmd("botright vsplit | terminal")
end, { desc = "Terminal: Vertical" })

-- Open a terminal in a full window
vim.keymap.set("n", "<leader>tt", function()
    vim.cmd("terminal")
end, { desc = "Terminal: Full window" })

 -- Leave terminal mode with Escape twice
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
    desc = "Terminal: Exit terminal mode",
})
