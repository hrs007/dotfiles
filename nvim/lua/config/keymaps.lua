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
