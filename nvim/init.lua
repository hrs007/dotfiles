-- Set leader keys before loading any modules or plugin mappings.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Neovide may temporarily advertise these extensions during startup-message
-- capture. That startup-only state must not prevent Noice loading at VeryLazy.
vim.g.neovide_noice_compatible = true

-- Finder launches GUI apps with a minimal PATH, so Neovide cannot find Node
-- installed through nvm. Restore the user's default nvm Node for GUI sessions
-- before Mason or any language servers are initialized.
if vim.g.neovide and vim.fn.has("mac") == 1 then
    local nvm_node_root = vim.fn.expand("~/.nvm/versions/node")
    local default_alias = vim.fn.expand("~/.nvm/alias/default")
    local alias_file = io.open(default_alias, "r")
    local default_version = alias_file and alias_file:read("*l") or nil
    if alias_file then alias_file:close() end

    local node_versions = {}
    if vim.fn.isdirectory(nvm_node_root) == 1 then
        for name, kind in vim.fs.dir(nvm_node_root) do
            if kind == "directory" then
                node_versions[#node_versions + 1] = name
            end
        end
    end
    table.sort(node_versions, function(a, b)
        return a > b
    end)

    local node_bin
    if default_version and default_version ~= "" then
        for _, version in ipairs(node_versions) do
            if version == default_version or version == "v" .. default_version
                or version:match("^v?" .. vim.pesc(default_version) .. "[%.%-]") then
                local candidate = vim.fs.joinpath(nvm_node_root, version, "bin")
                if vim.fn.executable(vim.fs.joinpath(candidate, "node")) == 1 then
                    node_bin = candidate
                    break
                end
            end
        end
    end

    if not node_bin then
        for _, version in ipairs(node_versions) do
            local candidate = vim.fs.joinpath(nvm_node_root, version, "bin")
            if vim.fn.executable(vim.fs.joinpath(candidate, "node")) == 1 then
                node_bin = candidate
                break
            end
        end
    end

    if node_bin then
        vim.env.PATH = node_bin .. (vim.env.PATH ~= "" and ":" .. vim.env.PATH or "")
    end
end

-- Use Oil for directory browsing instead of Neovim's built-in netrw.
-- These must be set before startup arguments (such as `nvim .`) are handled.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Load general editor settings from options.lua
require("config.options")
require("config.dashboard_startup")
require("config.lazygit")
require("config.swapfile").setup()

-- Some Neovim builds omit the Delete choice from the built-in swap dialog.
-- Provide an explicit command for removing the current buffer's swap file.
vim.api.nvim_create_user_command("DeleteSwap", function()
    local swapname = vim.fn.swapname(vim.api.nvim_get_current_buf())
    if swapname == "" or vim.fn.filereadable(swapname) ~= 1 then
        vim.notify("No swap file exists for the current buffer", vim.log.levels.INFO)
        return
    end

    local answer = vim.fn.confirm(
        "Delete swap file?\n" .. swapname,
        "&Delete\n&Cancel",
        2
    )
    if answer == 1 then
        local ok, err = os.remove(swapname)
        if ok then
            vim.notify("Deleted swap file: " .. swapname, vim.log.levels.INFO)
        else
            vim.notify("Could not delete swap file: " .. tostring(err), vim.log.levels.ERROR)
        end
    end
end, { desc = "Delete the current buffer's swap file" })

-- Load custom keyboard shortcuts from keymaps.lua
require("config.keymaps")
require("config.related_files")
require("config.web_routes").setup()
require("config.terminal_title")
require("config.code_actions").setup()

-- Load Windows-only C# editor shortcuts.
if vim.fn.has("win32") == 1 then
    require("config.csharp")
    require("config.csharp_unused").setup()
end
require("config.python_references").setup()
require("config.cpp_references").setup()
require("config.symbol_references").setup()
require("config.xaml")

-- Shared build/run workflow and Windows WPF commands.
require("config.language_workflow")
require("config.wpf")

-- load diagnostics ui for error
require("config.diagnostics")

-- Python project interpreter selection and BasedPyright environment support.
require("config.python")
require("config.formatting")

-- Initialize the plugin manager.
require("config.lazy")
