local M = {}
local pending_paths = {}

local function transfer_file()
    return vim.fs.joinpath(vim.fn.stdpath("state"), "oil-transfer.json")
end

local function save_paths(paths)
    local path = transfer_file()
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local ok, encoded = pcall(vim.json.encode, paths)
    if not ok then return false end
    return vim.fn.writefile({ encoded }, path) == 0
end

local function load_paths()
    local path = transfer_file()
    if vim.fn.filereadable(path) ~= 1 then return {} end
    local ok_read, lines = pcall(vim.fn.readfile, path)
    if not ok_read or type(lines) ~= "table" then return {} end
    if #lines == 0 then return {} end
    local ok, paths = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok or type(paths) ~= "table" then return {} end
    local valid = {}
    for _, path in ipairs(paths) do
        if type(path) == "string" and vim.uv.fs_stat(path) then
            valid[#valid + 1] = vim.fs.normalize(path)
        end
    end
    return valid
end

local function normalized(path)
    return vim.fs.normalize(path):gsub("\\", "/"):lower()
end

local function exists(path)
    return vim.uv.fs_stat(path) ~= nil
end

local function notify_error(title, result)
    local detail = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
    if detail == "" then detail = "The file operation failed." end
    vim.notify(title .. "\n" .. detail, vim.log.levels.ERROR, { title = "Oil file transfer" })
end

local function run_copy(source, destination, is_dir, callback)
    local command
    if vim.fn.has("win32") == 1 then
        local function quote(path)
            return "'" .. path:gsub("'", "''") .. "'"
        end
        local script
        if is_dir then
            script = "$ErrorActionPreference = 'Stop'; try { [System.IO.Directory]::CreateDirectory("
                .. quote(destination) .. ") | Out-Null; Get-ChildItem -LiteralPath " .. quote(source)
                .. " -Force | Copy-Item -Destination " .. quote(destination)
                .. " -Recurse -Force } catch { Write-Error $_; exit 1 }"
        else
            script = "$ErrorActionPreference = 'Stop'; try { Copy-Item -LiteralPath " .. quote(source)
                .. " -Destination " .. quote(destination) .. " -Force } catch { Write-Error $_; exit 1 }"
        end
        command = { "powershell.exe", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", script }
    elseif is_dir then
        command = { "sh", "-c", 'mkdir -p "$2" && cp -R "$1"/. "$2"/', "oil-copy", source, destination }
    else
        command = { "cp", "-f", source, destination }
    end

    vim.system(command, { text = true }, function(result)
        vim.schedule(function()
            callback(result)
        end)
    end)
end

local function refresh_oil(directory)
    vim.schedule(function()
        local ok, oil = pcall(require, "oil")
        if not ok or not oil.get_current_dir() then return end
        if normalized(oil.get_current_dir()) ~= normalized(directory) then return end
        -- Refresh the current Oil buffer in place. Opening another oil:// URL
        -- can collide with buffers restored by Neovim's restart session.
        pcall(vim.cmd.edit, { bang = true })
    end)
end

local function copy_next(paths, index, destination_dir, copied)
    if index > #paths then
        refresh_oil(destination_dir)
        vim.notify(("Copied %d item%s into %s"):format(
            copied, copied == 1 and "" or "s", vim.fn.fnamemodify(destination_dir, ":~")
        ), vim.log.levels.INFO, { title = "Oil file transfer" })
        return
    end

    local source = vim.fs.normalize(paths[index])
    local source_stat = vim.uv.fs_stat(source)
    if not source_stat then
        vim.notify("Source file no longer exists: " .. source, vim.log.levels.ERROR, { title = "Oil file transfer" })
        return
    end
    if normalized(source) == normalized(destination_dir) then
        return copy_next(paths, index + 1, destination_dir, copied)
    end

    local name = vim.fs.basename(source)
    local destination = vim.fs.joinpath(destination_dir, name)
    if normalized(source) == normalized(destination) then
        return copy_next(paths, index + 1, destination_dir, copied)
    end

    local is_dir = source_stat.type == "directory"
    local function perform_copy()
        run_copy(source, destination, is_dir, function(result)
            if result.code ~= 0 then return notify_error("Could not copy " .. name, result) end
            copy_next(paths, index + 1, destination_dir, copied + 1)
        end)
    end

    if exists(destination) then
        local choice = is_dir and "Merge folders" or "Overwrite"
        vim.ui.select({ choice, "Skip", "Cancel" }, {
            prompt = ("“%s” already exists in the destination."):format(name),
        }, function(selected)
            if selected == choice then
                perform_copy()
            elseif selected == "Skip" then
                copy_next(paths, index + 1, destination_dir, copied)
            end
        end)
    else
        perform_copy()
    end
end

function M.yank()
    local oil = require("oil")
    local bufnr = vim.api.nvim_get_current_buf()
    local directory = oil.get_current_dir()
    if not directory then return end

    local mode = vim.fn.mode()
    local visual = mode == "v" or mode == "V" or mode == "\22"
    local rows = {}
    if visual then
        -- Visual marks are finalized only after leaving visual mode. Capture
        -- the live anchor and cursor so the first yank sees the current range.
        local anchor = vim.fn.getpos("v")
        local first = anchor[2]
        local last = vim.api.nvim_win_get_cursor(0)[1]
        if first <= 0 or last <= 0 then
            first = vim.api.nvim_buf_get_mark(bufnr, "<")[1]
            last = vim.api.nvim_buf_get_mark(bufnr, ">")[1]
        end
        if first > last then first, last = last, first end
        for row = first, last do rows[#rows + 1] = row end
    else
        rows[1] = vim.api.nvim_win_get_cursor(0)[1]
    end

    local seen = {}
    pending_paths = {}
    for _, row in ipairs(rows) do
        local entry = oil.get_entry_on_line(bufnr, row)
        if entry and entry.name ~= ".." then
            local path = vim.fs.joinpath(directory, entry.name)
            local key = normalized(path)
            if not seen[key] then
                seen[key] = true
                pending_paths[#pending_paths + 1] = path
            end
        end
    end
    if #pending_paths == 0 then
        vim.notify("No files selected in this Oil window.", vim.log.levels.INFO)
        return
    end

    vim.fn.setreg(vim.v.register, table.concat(pending_paths, "\n"))
    if not save_paths(pending_paths) then
        vim.notify("Could not save paths for transfer between Neovim windows.", vim.log.levels.ERROR)
        return
    end
    vim.notify(("Yanked %d path%s. Move to another Oil window and press P to copy."):format(
        #pending_paths, #pending_paths == 1 and "" or "s"
    ), vim.log.levels.INFO, { title = "Oil file transfer" })
    if visual then
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "n", false)
    end
end

function M.paste()
    local oil = require("oil")
    local destination_dir = oil.get_current_dir()
    if not destination_dir then
        vim.notify("Open an Oil directory as the destination first.", vim.log.levels.WARN)
        return
    end

    local paths = load_paths()
    if #paths == 0 then paths = vim.deepcopy(pending_paths) end
    if #paths == 0 then
        vim.notify("Yank a file with y in an Oil window first.", vim.log.levels.WARN, { title = "Oil file transfer" })
        return
    end
    copy_next(paths, 1, destination_dir, 0)
end

return M

