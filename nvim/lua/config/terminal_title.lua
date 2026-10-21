-- Send the active Neovim context to terminal emulators such as Windows
-- Terminal through Neovim's built-in terminal title support.
local api = vim.api
local group = api.nvim_create_augroup("config.terminal_title", { clear = true })

local project_markers = {
    "*.sln", "*.slnx", "*.csproj", "*.fsproj", "*.vbproj",
    "package.json", "pyproject.toml", "Cargo.toml", "go.mod", "Makefile",
}

local function basename(path)
    return vim.fs.basename(path:gsub("[\\\\/]$", ""))
end

local function context_title()
    local buf = api.nvim_get_current_buf()
    local name = api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype == "terminal" or name:match("^term://") then
        local cwd = name:match("^term://(.-)//%d+:") or vim.b[buf].terminal_cwd or vim.fn.getcwd()
        return basename(cwd)
    end

    if name == "" or name:match("^oil://") then
        local cwd = vim.fn.getcwd()
        local ok, oil = pcall(require, "oil")
        if ok and name:match("^oil://") then
            cwd = oil.get_current_dir() or cwd
        end
        local root = vim.fs.root(cwd, project_markers)
        return root and basename(root) or basename(cwd)
    end

    local path = vim.fs.normalize(name)
    local root = vim.fs.root(path, project_markers)
    return root and basename(root) or basename(vim.fs.dirname(path))
end

local function update_title()
    local title = context_title():gsub("[\r\n\7\27]", " "):gsub("%%", "%%%%")
    vim.o.titlestring = title
end

vim.o.title = true
vim.o.titlelen = 80
update_title()

api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "DirChanged", "TermOpen" }, {
    group = group,
    callback = function()
        vim.schedule(update_title)
    end,
    desc = "Update terminal tab title from the active Neovim context",
})
