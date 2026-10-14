-- Set leader keys before loading any modules or plugin mappings.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load general editor settings from options.lua
require("config.options")

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

-- Initialize the plugin manager.
require("config.lazy")
