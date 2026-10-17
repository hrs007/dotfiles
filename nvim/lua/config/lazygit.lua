local M = {}

local active
local resize_group = vim.api.nvim_create_augroup("config.lazygit", { clear = true })

local function is_valid_win(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function geometry()
    local width = math.max(1, math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.92)))
    local height = math.max(1, math.min(vim.o.lines - 6, math.floor(vim.o.lines * 0.88)))
    return {
        relative = "editor",
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        style = "minimal",
        border = "rounded",
        title = " LazyGit ",
        title_pos = "center",
    }
end

vim.api.nvim_create_autocmd("VimResized", {
    group = resize_group,
    callback = function()
        if active and is_valid_win(active.win) then
            pcall(vim.api.nvim_win_set_config, active.win, geometry())
        end
    end,
})

local function git_root(directory)
    local output = vim.fn.systemlist({ "git", "-C", directory, "rev-parse", "--show-toplevel" })
    if vim.v.shell_error ~= 0 or not output[1] or output[1] == "" then
        return nil
    end
    return output[1]
end

local function restore_window(session)
    if vim.api.nvim_tabpage_is_valid(session.previous_tab) then
        pcall(vim.api.nvim_set_current_tabpage, session.previous_tab)
    end
    if is_valid_win(session.previous_win) then
        pcall(vim.api.nvim_set_current_win, session.previous_win)
    end
end

local function focus_active()
    if not active or not is_valid_win(active.win) then
        return false
    end
    pcall(vim.api.nvim_set_current_tabpage, active.tab)
    pcall(vim.api.nvim_set_current_win, active.win)
    vim.cmd("startinsert")
    return true
end

local function open(cwd)
    if vim.fn.executable("lazygit") ~= 1 then
        vim.notify("LazyGit is not installed or is missing from PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_active() then return end

    local session = {
        previous_win = vim.api.nvim_get_current_win(),
        previous_tab = vim.api.nvim_get_current_tabpage(),
        tab = vim.api.nvim_get_current_tabpage(),
    }
    local buffer = vim.api.nvim_create_buf(false, true)
    session.buffer = buffer
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].swapfile = false

    local ok, win = pcall(vim.api.nvim_open_win, buffer, true, geometry())
    if not ok then
        vim.api.nvim_buf_delete(buffer, { force = true })
        vim.notify("Could not open the LazyGit window: " .. tostring(win), vim.log.levels.ERROR)
        return
    end
    session.win = win
    active = session
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = resize_group,
        buffer = buffer,
        once = true,
        callback = function()
            if active == session then
                active = nil
                if session.job then pcall(vim.fn.jobstop, session.job) end
                vim.schedule(function() restore_window(session) end)
            end
        end,
    })

    local job = vim.fn.jobstart({ "lazygit" }, {
        term = true,
        cwd = cwd,
        on_exit = function(_, code)
            vim.schedule(function()
                if active ~= session then return end
                active = nil
                if is_valid_win(session.win) then
                    pcall(vim.api.nvim_win_close, session.win, true)
                end
                if vim.api.nvim_buf_is_valid(session.buffer) then
                    pcall(vim.api.nvim_buf_delete, session.buffer, { force = true })
                end
                restore_window(session)
                if code ~= 0 then
                    vim.notify(("LazyGit exited with status %s."):format(code), vim.log.levels.ERROR)
                end
            end)
        end,
    })

    if job <= 0 then
        active = nil
        if is_valid_win(win) then pcall(vim.api.nvim_win_close, win, true) end
        if vim.api.nvim_buf_is_valid(buffer) then pcall(vim.api.nvim_buf_delete, buffer, { force = true }) end
        restore_window(session)
        vim.notify("Neovim could not start LazyGit.", vim.log.levels.ERROR)
        return
    end
    session.job = job
    vim.bo[buffer].filetype = "lazygit"

    vim.cmd("startinsert")
end

function M.open_current_directory()
    open(vim.fn.getcwd())
end

function M.open_current_file()
    local buffer = vim.api.nvim_get_current_buf()
    local filename = vim.api.nvim_buf_get_name(buffer)
    local directory
    if vim.bo[buffer].buftype == "terminal" or filename == "" then
        directory = vim.fn.getcwd()
    else
        directory = vim.fn.fnamemodify(filename, ":p:h")
    end
    local root = git_root(directory)
    if not root then
        vim.notify("The current file is not inside a Git repository.", vim.log.levels.WARN)
        return
    end
    open(root)
end

vim.api.nvim_create_user_command("LazyGit", M.open_current_directory, { desc = "Open LazyGit in the current directory" })
vim.api.nvim_create_user_command("LazyGitCurrentFile", M.open_current_file, { desc = "Open LazyGit for the current file's repository" })

vim.keymap.set("n", "<leader>gL", M.open_current_directory, { desc = "Git: LazyGit" })
vim.keymap.set("n", "<leader>gF", M.open_current_file, { desc = "Git: LazyGit current file" })

return M
