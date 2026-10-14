local opt = vim.opt

-- Give leader-key sequences enough time to complete comfortably.
opt.timeout = true
opt.timeoutlen = 2000

vim.cmd("filetype plugin indent on")

-- Treat WPF XAML as XML for syntax, LSP, and formatting support.
vim.filetype.add({
    extension = {
        xaml = "xml",
    },
})

-- Editing
opt.number = true
opt.relativenumber = true
opt.cursorline = true
-- Highlight the full current line.
opt.cursorlineopt = "line"
opt.wrap = false
opt.scrolloff = 5
opt.sidescrolloff = 5
opt.virtualedit = "block"
opt.backspace = { "indent", "eol", "start" }

-- Indentation
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.autoindent = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Interface
opt.showmode = false
opt.showcmd = false
opt.ruler = false
-- Keep one sign column normally, and allow a second only when diagnostics and
-- Git hunk signs need to appear on the same line.
opt.signcolumn = "auto:2"
opt.laststatus = 3
opt.termguicolors = true
opt.mouse = "a"
opt.list = true
opt.listchars = {
    tab = "» ",
    trail = "·",
    extends = "›",
    precedes = "‹",
}

-- Files and windows
opt.clipboard = "unnamedplus"
opt.hidden = true
-- Prompt before abandoning any modified buffer, including staged Oil edits.
opt.confirm = true
opt.autoread = true
opt.undofile = true
opt.splitbelow = true
opt.splitright = true
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"
opt.wildmenu = true
opt.wildmode = { "longest:full", "full" }

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

-- Keep Neovide's GUI behavior close to terminal Neovim. These globals are
-- ignored by regular Neovim and preserve multigrid/floating UI support.
if vim.g.neovide then
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_short_animation_length = 0
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_cursor_smooth_blink = false
    vim.g.neovide_cursor_vfx_mode = ""
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_scroll_animation_far_lines = 0
    vim.g.neovide_floating_blur_amount_x = 0
    vim.g.neovide_floating_blur_amount_y = 0
    vim.g.neovide_floating_shadow = false
    vim.g.neovide_floating_corner_radius = 0
    vim.g.neovide_progress_bar_enabled = false
end
