-- Load general editor settings from options.lua
require("config.options")

-- Load custom keyboard shortcuts from keymaps.lua
require("config.keymaps")

-- Load language-specific editor shortcuts.
require("config.csharp")
require("config.xaml")

-- Shared build/run workflow and Windows WPF commands.
require("config.language_workflow")
require("config.wpf")

-- load diagnostics ui for error
require("config.diagnostics")

-- Initialize the plugin manager.
require("config.lazy")
