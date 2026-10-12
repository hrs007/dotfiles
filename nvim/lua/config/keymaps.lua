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

-- Window management uses Space p to avoid existing save and WPF mappings.
map("n", "<leader>ph", "<cmd>split<CR>", { desc = "Window: Split below" })
map("n", "<leader>pv", "<cmd>vsplit<CR>", { desc = "Window: Split right" })
map("n", "<leader>pe", "<C-w>=", { desc = "Window: Balance sizes" })
map("n", "<leader>po", "<C-w>o", { desc = "Window: Close others" })
map("n", "<leader>pH", "<C-w><", { desc = "Window: Narrow" })
map("n", "<leader>pL", "<C-w>>", { desc = "Window: Widen" })
map("n", "<leader>pJ", "<C-w>-", { desc = "Window: Shorten" })
map("n", "<leader>pK", "<C-w>+", { desc = "Window: Heighten" })


-- Set up keymaps when an LSP attaches to a buffer.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        -- Only apply these mappings to the current buffer.
        local opts = { buffer = event.buf, silent = true }

        -- Go to the definition of a symbol.
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

        -- Go to implementations, useful for interface and abstract members.
        vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)

        -- Find references to a symbol.
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

        -- Show documentation and type information.
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

        -- Rename a symbol.
        vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, opts)

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

-- Keep one reusable horizontal terminal for long-running jobs such as Vite.
local toggle_terminal_buf

local function hide_terminal()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "terminal" then
        return
    end

    vim.cmd("stopinsert")
    if #vim.api.nvim_list_wins() > 1 then
        vim.api.nvim_win_close(win, true)
    else
        local alternate = vim.fn.bufnr("#")
        if alternate > 0 and vim.api.nvim_buf_is_valid(alternate) and alternate ~= buf then
            vim.api.nvim_win_set_buf(win, alternate)
        else
            vim.cmd("enew")
        end
    end
end

local function toggle_terminal()
    if toggle_terminal_buf and vim.api.nvim_buf_is_valid(toggle_terminal_buf) then
        local terminal_win
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == toggle_terminal_buf then
                terminal_win = win
                break
            end
        end

        if terminal_win then
            vim.api.nvim_set_current_win(terminal_win)
            hide_terminal()
            return
        end

        vim.cmd("botright 12split")
        vim.api.nvim_win_set_buf(0, toggle_terminal_buf)
        vim.cmd("startinsert")
        return
    end

    vim.cmd("botright 12split | terminal")
    toggle_terminal_buf = vim.api.nvim_get_current_buf()
    vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>th", toggle_terminal, {
    desc = "Terminal: Toggle persistent shell",
})

-- Open a terminal in a vertical split
vim.keymap.set("n", "<leader>tv", function()
    vim.cmd("botright vsplit | terminal")
end, { desc = "Terminal: Vertical" })

-- Open a terminal in a full window
vim.keymap.set("n", "<leader>tt", function()
    vim.cmd("terminal")
end, { desc = "Terminal: Full window" })

-- Stop the terminal job, remove its buffer, and close its split.
local function close_terminal()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "terminal" then
        return
    end

    vim.cmd("stopinsert")
    if buf == toggle_terminal_buf then
        toggle_terminal_buf = nil
    end
    if vim.api.nvim_win_is_valid(win) and #vim.api.nvim_list_wins() > 1 then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

vim.keymap.set("t", "<C-q>", hide_terminal, {
    desc = "Terminal: Hide",
})

-- Leave terminal input mode without hiding or stopping the running job.
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", {
    desc = "Terminal: Normal mode",
})
vim.keymap.set("t", "<C-\\><C-n>", hide_terminal, {
    desc = "Terminal: Hide",
})

-- In terminal normal mode, q closes the terminal instead of starting a macro.
vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(args)
        vim.keymap.set("n", "q", close_terminal, {
            buffer = args.buf,
            desc = "Terminal: Close",
        })
    end,
})

-- Keep q as the close key in quickfix and Diffview panels too.
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "qf", "DiffviewFiles", "DiffviewFileHistory" },
    callback = function(args)
        local close_command = args.match == "qf" and "close" or "DiffviewClose"
        vim.keymap.set("n", "q", "<Cmd>" .. close_command .. "<CR>", {
            buffer = args.buf,
            desc = "Close panel",
        })
    end,
})

-- ==========================================
-- Workspace Symbols
-- ==========================================

-- Search for classes, functions, methods, and other symbols
-- across the workspace using Telescope and the attached LSP.
map("n", "<leader>fw", function()
    require("telescope.builtin").lsp_dynamic_workspace_symbols()
end, {
    desc = "Find workspace symbols",
})
