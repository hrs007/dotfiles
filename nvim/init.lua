-- Load general editor settings from options.lua
require("config.options")

-- Load custom keyboard shortcuts from keymaps.lua
require("config.keymaps")

-- load diagnostics ui for error
require("config.diagnostics")

-- Initialize the plugin manager.
require("config.lazy")
