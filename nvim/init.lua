-- Set leader keys before loading any modules or plugin mappings.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load general editor settings from options.lua
require("config.options")
require("config.dashboard_startup")

-- Nvim 0.12 skips the swapfile dialog for swaps owned by a running Nvim
-- process. Clear its default handler after startup so recovery choices show.
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        pcall(vim.api.nvim_clear_autocmds, {
            group = "nvim.swapfile",
            event = "SwapExists",
        })
    end,
    desc = "Keep Neovim's swapfile recovery prompt enabled",
})

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

-- Load Windows-only C# editor shortcuts.
if vim.fn.has("win32") == 1 then
    require("config.csharp")
end
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
