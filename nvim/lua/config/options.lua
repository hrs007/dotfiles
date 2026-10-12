local opt = vim.opt

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
opt.cursorlineopt = "number"
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
opt.signcolumn = "yes"
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
opt.autoread = true
opt.undofile = true
opt.splitbelow = true
opt.splitright = true
opt.wildmenu = true
opt.wildmode = { "longest:full", "full" }

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
