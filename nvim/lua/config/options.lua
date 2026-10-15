local opt = vim.opt

-- Give leader-key sequences enough time to complete comfortably.
opt.timeout = true
opt.timeoutlen = 400
-- Keep idle callbacks and redraw recovery responsive without forcing
-- expensive UI work on every keystroke.
opt.updatetime = 200

vim.cmd("filetype plugin indent on")

-- Treat WPF XAML as XML for syntax, LSP, and formatting support.
vim.filetype.add({
    extension = {
        xaml = "xml",
    },
})

-- Oil can leave a file buffer with its directory-browser filetype after
-- opening a source file. Restore the filename-based type for C# documents so
-- Roslyn receives `languageId = csharp` and publishes compiler diagnostics.
local csharp_filetype_group = vim.api.nvim_create_augroup("config.csharp_filetype", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
    group = csharp_filetype_group,
    callback = function(event)
        local bufnr = event.buf
        local filename = vim.api.nvim_buf_get_name(bufnr)
        if not filename:lower():match("%.cs$") or vim.bo[bufnr].filetype == "cs" then
            return
        end

        vim.bo[bufnr].filetype = "cs"
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
                if client.name:lower():find("roslyn", 1, true) then
                    pcall(vim.lsp.buf_detach_client, bufnr, client.id)
                    pcall(vim.lsp.buf_attach_client, bufnr, client.id)
                end
            end
        end)
    end,
    desc = "Use C# filetype for .cs files opened from Oil",
})

-- Editing
opt.number = true
opt.relativenumber = true
opt.cursorline = true
-- Highlight the full current line.
opt.cursorlineopt = "line"
opt.wrap = false
-- Avoid spending excessive time syntax-highlighting generated/minified lines.
opt.synmaxcol = 3000
-- Use Neovim's smoother screen-line scrolling for half-page motions.
opt.smoothscroll = true
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
-- Noice provides the command-line popup; don't reserve an empty row below
-- the editor when the command line is idle.
opt.cmdheight = 0
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
    -- Use platform-appropriate GUI sizes: the compact Windows size was too
    -- small on macOS displays. Linux keeps Neovide's config-file size.
    if vim.fn.has("win32") == 1 then
        vim.o.guifont = "JetBrainsMonoNL_NF:h10"
    elseif vim.fn.has("mac") == 1 then
        vim.o.guifont = "JetBrainsMono_Nerd_Font_Mono:h18"
    end
    vim.g.neovide_position_animation_length = 0
    -- Keep motion feedback subtle and short so it feels smooth without making
    -- cursor movement feel delayed.
    vim.g.neovide_cursor_animation_length = 0.06
    vim.g.neovide_cursor_short_animation_length = 0.04
    vim.g.neovide_cursor_trail_size = 0.1
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_cursor_smooth_blink = false
    vim.g.neovide_cursor_vfx_mode = ""
    vim.g.neovide_scroll_animation_length = 0.12
    vim.g.neovide_scroll_animation_far_lines = 3
    vim.g.neovide_floating_blur_amount_x = 0
    vim.g.neovide_floating_blur_amount_y = 0
    vim.g.neovide_floating_shadow = false
    vim.g.neovide_floating_corner_radius = 0
    vim.g.neovide_progress_bar_enabled = false
end
