autocmd TextChanged,TextChangedI * silent! update
syntax on

" Use terminal colors with a dark background for readable built-in highlights.
set background=dark
if &termguicolors
    set termguicolors
endif

" Keep line numbers subtle on dark backgrounds, while emphasizing the current line.
highlight LineNr ctermfg=DarkGray guifg=#6c7086 guibg=NONE
highlight CursorLineNr ctermfg=Cyan cterm=bold guifg=#89b4fa guibg=NONE gui=bold

" Enable filetype detection, plugins, and indentation
filetype plugin indent on

" Show absolute line numbers
set number

" Show relative line numbers for easier movement
set relativenumber

" Subtle current-line highlight that follows the active dark colorscheme.
set cursorline
highlight CursorLine cterm=NONE gui=NONE ctermbg=234 guibg=#191a24

"Highlight the matching bracket
set showmatch

" Use the system clipboard when this Vim build provides it.
if has('clipboard')
    set clipboard=unnamed,unnamedplus
endif

" Use UTF-8
set encoding=utf-8

" Disable compatibility with old Vi
set nocompatible

" Show current command as you type
set showcmd

" Display incomplete commands in the status line
set showmode

" Keep some context around the cursor
set scrolloff=5

" Keep a few columns visible horizontally
set sidescrolloff=5

" Convert tabs to spaces
set expandtab

" Number of spaces inserted by Tab
set tabstop=4

" Number of spaces used for automatic indentation
set shiftwidth=4

" Number of spaces used when pressing Tab in Insert mode
set softtabstop=4

" Preserve indentation from the previous line
set autoindent

" Smart indentation for programming
set smartindent

" Ignore case when searching
set ignorecase

" Override ignorecase when search contains uppercase
set smartcase

" Highlight matching search results
set hlsearch

" Show matches while typing a search
set incsearch

" Clear search highlighting with Esc
nnoremap <Esc> :nohlsearch<CR><Esc>

" Match Neovim's Space-leader shortcuts.
let mapleader = ' '
nnoremap <Space> <Nop>
nnoremap <silent> <leader>ww :write<CR>
nnoremap <silent> <leader>q :quit<CR>
nnoremap <silent> <Esc> :nohlsearch<CR>

" Navigate between splits with Ctrl-h/j/k/l.
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-l> <C-w>l

" Match Neovim's Space+w window-management shortcuts.
nnoremap <silent> <leader>wh :split<CR>
nnoremap <silent> <leader>wv :vsplit<CR>
nnoremap <silent> <leader>wc :close<CR>
nnoremap <silent> <leader>we <C-w>=
nnoremap <silent> <leader>wo <C-w>o

" Match Neovim's buffer navigation and management shortcuts.
nnoremap <silent> <S-l> :bnext<CR>
nnoremap <silent> <S-h> :bprevious<CR>
nnoremap <silent> <leader>vl :bnext<CR>
nnoremap <silent> <leader>vh :bprevious<CR>
nnoremap <silent> <leader>vn :enew<CR>
nnoremap <silent> <leader>vd :bdelete<CR>
nnoremap <silent> Q :bdelete<CR>
nnoremap <silent> <leader>vp :buffers<CR>:buffer<Space>
nnoremap <silent> <leader>vH :bprevious<CR>
nnoremap <silent> <leader>vL :bnext<CR>

" Move selected lines up or down in Visual mode.
xnoremap J :move '>+1<CR>gv=gv
xnoremap K :move '<-2<CR>gv=gv

"Keep the cursor centered while navigating search results
nnoremap n nzzzv
nnoremap N Nzzzv

"Keep the cursor centered during jumps
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

"Show whitespace characters
set list
set listchars=tab:»\ ,trail:·,extends:›,precedes:‹

" Enable mouse support in the terminal
set mouse=a

" Allow hidden buffers with unsaved changes
" (useful when switching between files)
set hidden

" Improve backspace behavior
set backspace=indent,eol,start

" Allow cursor to move freely in visual block mode
set virtualedit=block

" Do not wrap long lines
set nowrap

" Automatically read files changed outside Vim
set autoread


" ==========================================
" Completion
" ==========================================

" Show a menu for completion
set wildmenu

" Improve command-line completion
set wildmode=longest:full,full


" ==========================================
" Splits
" ==========================================

" Open horizontal splits below the current window
set splitbelow

" Open vertical splits to the right
set splitright


" ==========================================
" Undo
" ==========================================

" Keep undo history between editing sessions
if has('persistent_undo')
    if has('win32') || has('win64')
        let s:vim_data_dir = expand('$LOCALAPPDATA') . '/vim'
    elseif !empty($XDG_DATA_HOME)
        let s:vim_data_dir = expand('$XDG_DATA_HOME') . '/vim'
    else
        let s:vim_data_dir = expand('~/.vim')
    endif
    if !isdirectory(s:vim_data_dir . '/undo')
        call mkdir(s:vim_data_dir . '/undo', 'p', 0700)
    endif
    let &undodir = s:vim_data_dir . '/undo//'
    set undofile
endif


" ==========================================
" Interface
" ==========================================

" Show the current cursor position
set ruler

" Always show the status line
"set laststatus=2

" Allow more space for messages
"set cmdheight=1

" Set a reasonable command history size
"set history=1000

" Faster response for key mappings
"set timeoutlen=500

