-- Use vim.opt to configure Neovim options through Lua.
local opt = vim.opt


-- ==========================================
-- Syntax and Filetype Detection
-- ==========================================

-- Enable syntax highlighting for supported filetypes.
-- Tree-sitter can provide enhanced highlighting later.
vim.cmd("syntax on")

-- Enable filetype detection, filetype-specific plugins,
-- and filetype-specific indentation rules.
vim.cmd("filetype plugin indent on")


-- ==========================================
-- Line Numbers
-- ==========================================

-- Display absolute line numbers in the gutter.
opt.number = true

-- Display relative line numbers for easier movement
-- using commands such as 5j or 10k.
opt.relativenumber = true

-- Highlight the screen line containing the cursor.
opt.cursorline = true


-- ==========================================
-- Matching Brackets
-- ==========================================

-- Briefly highlight the matching bracket when the cursor
-- is positioned on a parenthesis, bracket, or brace.
opt.showmatch = true


-- ==========================================
-- System Clipboard
-- ==========================================

-- Use the system clipboard for ordinary yank, delete,
-- change, and put operations.
-- This allows copying and pasting between Neovim and
-- other applications when clipboard support is available.
opt.clipboard = "unnamedplus"


-- ==========================================
-- Command and Mode Information
-- ==========================================

-- Display partial commands in the command area as you type.
-- For example, this helps show a partially entered command.
opt.showcmd = true

-- Display the current editing mode when applicable,
-- such as -- INSERT -- or -- VISUAL --.
opt.showmode = false


-- ==========================================
-- Scrolling and Navigation
-- ==========================================

-- Keep at least five screen lines visible above and below
-- the cursor when possible.
opt.scrolloff = 5

-- Keep at least five screen columns visible to the left
-- and right of the cursor when possible.
opt.sidescrolloff = 5

-- Allow the cursor to move freely through virtual columns
-- in Visual Block mode, even beyond existing text.
opt.virtualedit = "block"

-- Disable automatic line wrapping.
-- Long lines continue horizontally instead of wrapping
-- onto additional screen lines.
opt.wrap = false


-- ==========================================
-- Indentation
-- ==========================================

-- Insert spaces instead of literal tab characters
-- when pressing Tab in Insert mode.
opt.expandtab = true

-- Define a tab character as occupying four screen columns.
opt.tabstop = 4

-- Use four spaces for each indentation level when
-- indenting or unindenting lines.
opt.shiftwidth = 4

-- Use four spaces when pressing Tab or Backspace
-- in situations involving soft indentation.
opt.softtabstop = 4

-- Automatically preserve the indentation of the
-- preceding line when starting a new line.
opt.autoindent = true

-- Enable additional automatic indentation heuristics
-- intended for programming languages.
opt.smartindent = true


-- ==========================================
-- Search
-- ==========================================

-- Ignore letter case when searching by default.
-- For example, /hello also matches HELLO.
opt.ignorecase = true

-- Override ignorecase when the search contains uppercase
-- characters. For example, /Hello becomes case-sensitive.
opt.smartcase = true

-- Highlight all matches of the current search pattern.
opt.hlsearch = true

-- Show search matches incrementally while typing a pattern.
opt.incsearch = true


-- ==========================================
-- Whitespace Visualization
-- ==========================================

-- Display normally invisible whitespace characters.
opt.list = true

-- Customize the symbols used to represent whitespace:
-- tab      = show tabs using » followed by a space.
-- trail    = show trailing spaces using ·.
-- extends  = show an indicator when text extends right.
-- precedes = show an indicator when text extends left.
opt.listchars = {
    tab = "» ",
    space = "·",
    trail = "·",
    extends = "›",
    precedes = "‹",
}


-- Enable mouse interaction in supported terminals.
-- You can click, select text, and interact with windows.
opt.mouse = "a"


-- ==========================================
-- Buffers
-- ==========================================

-- Allow buffers to remain hidden when switching to another
-- buffer, even if the current buffer has unsaved changes.
-- This does not automatically save those changes.
opt.hidden = true


-- ==========================================
-- Backspace Behavior
-- ==========================================

-- Allow Backspace to delete:
-- indent = indentation inserted automatically.
-- eol    = the line break between two lines.
-- start  = text before the start of the current Insert mode.
opt.backspace = { "indent", "eol", "start" }


-- ==========================================
-- Line Wrapping
-- ==========================================

-- Do not visually wrap long lines.
-- The cursor may move horizontally to reach off-screen text.
opt.wrap = false


-- ==========================================
-- External File Changes
-- ==========================================

-- Check whether files have changed outside Neovim.
-- This is useful when another program modifies an open file.
-- It does not automatically save changes made inside Neovim.
opt.autoread = true


-- ==========================================
-- Command-Line Completion
-- ==========================================

-- Display a completion menu when completing commands
-- and paths on the command line.
opt.wildmenu = true

-- First complete to the longest common match, then provide
-- more completion choices when cycling through candidates.
opt.wildmode = { "longest:full", "full" }


-- ==========================================
-- Window Splits
-- ==========================================

-- Open new horizontal splits below the current window.
opt.splitbelow = true

-- Open new vertical splits to the right of the current window.
opt.splitright = true


-- ==========================================
-- Persistent Undo
-- ==========================================

-- Save undo history to a file so that undo history can
-- survive closing and reopening a file.
-- Neovim supports persistent undo through undofile.
opt.undofile = true


-- ==========================================
-- Interface
-- ==========================================

-- Display the current line and column in the ruler.
opt.ruler = true

-- Reserve space for diagnostic messages, Git indicators,
-- and other signs in the editor's sign column.
opt.signcolumn = "yes"

-- Enable true-color terminal output for themes and plugins
-- when the terminal supports it.
opt.termguicolors = true


-- ==========================================
-- Automatic Saving
-- ==========================================

-- Your original Vim configuration contained:
-- autocmd TextChanged,TextChangedI * silent! update
--
-- That command attempted to save modified files whenever
-- their contents changed, including during Insert mode.
--
-- It is intentionally not enabled here because it can
-- write files while you are still editing.
-- We can add a deliberate autosave mechanism later if needed.
--
--
-- -- ==========================================
-- Code Folding
-- ==========================================

-- Use Tree-sitter to determine fold boundaries.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Keep folds open when a file is first opened.
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Enable folding.
vim.opt.foldenable = true
