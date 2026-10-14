-- Create a local reference to Neovim's keymap function.
-- This avoids repeatedly writing vim.keymap.set.
local map = vim.keymap.set


-- ==========================================
-- Leader Keys
-- ==========================================

-- Reserve Space as a prefix instead of moving the cursor in Normal mode.
map("n", "<Space>", "<Nop>", { desc = "Leader key" })


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

-- Resize the active split in the direction that matches its shape. This also
-- works for Trouble, terminals, Oil, quickfix, and Git panels opened in splits.
local panel_sizes = {}
local function panel_axis(win)
    local position = vim.api.nvim_win_get_position(win)
    local y, x = position[1], position[2]
    local width, height = vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
    local best_overlap, vertical = 0, nil
    for _, other in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if other ~= win and vim.api.nvim_win_get_config(other).relative == "" then
            local other_position = vim.api.nvim_win_get_position(other)
            local oy, ox = other_position[1], other_position[2]
            local ow, oh = vim.api.nvim_win_get_width(other), vim.api.nvim_win_get_height(other)
            local overlap_x = math.max(0, math.min(x + width, ox + ow) - math.max(x, ox))
            local overlap_y = math.max(0, math.min(y + height, oy + oh) - math.max(y, oy))
            local overlap = math.max(overlap_x, overlap_y)
            if overlap > best_overlap then
                best_overlap = overlap
                vertical = overlap_y >= overlap_x
            end
        end
    end
    -- In a split layout, a tall shared edge means side-by-side windows; a
    -- wide shared edge means stacked windows. Fall back to the panel shape
    -- when the active window has no neighboring split.
    if vertical == nil then
        return width < height
    end
    return vertical
end

local function resize_active_panel(direction)
    local win = vim.api.nvim_get_current_win()
    local vertical = panel_axis(win)
    local size = vertical and vim.api.nvim_win_get_width(win) or vim.api.nvim_win_get_height(win)
    local step = vertical and 8 or 3
    local minimum = vertical and 24 or 5
    local maximum = vertical and math.max(minimum, vim.o.columns - 24) or math.max(minimum, vim.o.lines - 6)
    local next_size = math.min(maximum, math.max(minimum, size + direction * step))
    local ok = pcall(function()
        if vertical then
            vim.api.nvim_win_set_width(win, next_size)
        else
            vim.api.nvim_win_set_height(win, next_size)
        end
    end)
    if ok then
        vim.cmd("redraw!")
    end
end

local function toggle_active_panel_size()
    local win = vim.api.nvim_get_current_win()
    local vertical = panel_axis(win)
    local saved = panel_sizes[win]
    if saved then
        pcall(function()
            if saved.vertical then
                vim.api.nvim_win_set_width(win, saved.size)
            else
                vim.api.nvim_win_set_height(win, saved.size)
            end
        end)
        panel_sizes[win] = nil
        vim.cmd("redraw!")
        return
    end

    local size = vertical and vim.api.nvim_win_get_width(win) or vim.api.nvim_win_get_height(win)
    panel_sizes[win] = { size = size, vertical = vertical }
    local target = vertical and math.min(math.max(24, vim.o.columns - 24), math.floor(vim.o.columns * 0.55))
        or math.max(5, math.min(vim.o.lines - 6, math.max(8, math.floor(vim.o.lines * 0.55))))
    pcall(function()
        if vertical then
            vim.api.nvim_win_set_width(win, target)
        else
            vim.api.nvim_win_set_height(win, target)
        end
    end)
    vim.cmd("redraw!")
end

map("n", "<leader>p+", function() resize_active_panel(1) end, { desc = "Panel: Increase size" })
map("n", "<leader>p-", function() resize_active_panel(-1) end, { desc = "Panel: Decrease size" })
map("n", "<leader>p=", toggle_active_panel_size, { desc = "Panel: Maximize / restore" })

vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(event)
        panel_sizes[tonumber(event.match)] = nil
    end,
})


-- Diagnostic controls: visibility toggles are session-only, while rule ignores
-- can be saved for the current project or every project.
map("n", "<leader>ne", function()
    require("config.diagnostics").toggle_severity(vim.diagnostic.severity.ERROR, "Errors")
end, { desc = "Diagnostics: Toggle errors" })
map("n", "<leader>nw", function()
    require("config.diagnostics").toggle_severity(vim.diagnostic.severity.WARN, "Warnings")
end, { desc = "Diagnostics: Toggle warnings" })
map("n", "<leader>ni", function()
    require("config.diagnostics").ignore_current_rule()
end, { desc = "Diagnostics: Ignore rule" })
map("n", "<leader>nu", function()
    require("config.diagnostics").unignore_rule()
end, { desc = "Diagnostics: Manage ignored rules" })
map("n", "<leader>ns", function()
    require("config.diagnostics").toggle_signs()
end, { desc = "Diagnostics: Toggle signs" })
map("n", "<leader>nf", "<Cmd>FormatOnSaveToggle<CR>", {
    desc = "Formatting: Toggle format on save",
})
map("n", "<leader>cR", function()
    local bufnr = vim.api.nvim_get_current_buf()
    require("config.diagnostics").select_profile(bufnr)
end, { desc = "Diagnostics: Configure rule profile" })

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
        vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, {
            desc = "Code: Rename symbol",
        }))

        -- Show available code actions.
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, {
            desc = "Code: Actions / fixes",
        }))

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

local function current_python_environment()
    return require("config.python").environment_for_buffer(vim.api.nvim_get_current_buf())
end

local function activate_python_environment(buf, environment, on_ready)
    if not environment or not vim.api.nvim_buf_is_valid(buf) then
        if on_ready then on_ready() end
        return
    end
    if vim.b[buf].python_venv == environment then
        if on_ready then on_ready() end
        return
    end

    vim.b[buf].python_venv = environment
    vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
            return
        end
        local job = vim.b[buf].terminal_job_id
        if not job then
            return
        end

        local shell = vim.o.shell:lower()
        local command
        if shell:match("powershell") or shell:match("pwsh") then
            local script = vim.fs.joinpath(environment, "Scripts", "Activate.ps1")
            command = "& '" .. script:gsub("'", "''") .. "'"
        elseif shell:match("cmd%.exe") or shell:match("\\cmd$") then
            local script = vim.fs.joinpath(environment, "Scripts", "activate.bat")
            command = 'call "' .. script .. '"'
        elseif shell:match("fish") then
            local script = vim.fs.joinpath(environment, "bin", "activate.fish")
            command = ". " .. vim.fn.shellescape(script)
        else
            local script = vim.fs.joinpath(environment, "bin", "activate")
            if vim.fn.filereadable(script) ~= 1 then
                -- Windows virtual environments also provide a POSIX activation
                -- script for shells such as Git Bash.
                script = vim.fs.joinpath(environment, "Scripts", "activate")
            end
            command = "source " .. vim.fn.shellescape(script)
        end

        vim.api.nvim_chan_send(job, command .. "\n")
        if on_ready then on_ready() end
    end, 120)
end

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
    local python_environment = current_python_environment()
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
    activate_python_environment(toggle_terminal_buf, python_environment, function()
        if vim.api.nvim_get_current_buf() == toggle_terminal_buf then
            vim.cmd("startinsert")
        end
    end)
end

vim.keymap.set("n", "<leader>th", toggle_terminal, {
    desc = "Terminal: Toggle persistent shell",
})

-- Open a terminal in a vertical split
vim.keymap.set("n", "<leader>tv", function()
    local python_environment = current_python_environment()
    vim.cmd("botright vsplit | terminal")
    local buf = vim.api.nvim_get_current_buf()
    activate_python_environment(buf, python_environment, function()
        if vim.api.nvim_get_current_buf() == buf then vim.cmd("startinsert") end
    end)
end, { desc = "Terminal: Vertical" })

-- Open a terminal in a full window
vim.keymap.set("n", "<leader>tt", function()
    local python_environment = current_python_environment()
    vim.cmd("terminal")
    local buf = vim.api.nvim_get_current_buf()
    activate_python_environment(buf, python_environment, function()
        if vim.api.nvim_get_current_buf() == buf then vim.cmd("startinsert") end
    end)
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
