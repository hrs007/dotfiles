-- Load general editor settings from options.lua
require("config.options")

-- Load custom keyboard shortcuts from keymaps.lua
require("config.keymaps")

-- Initialize the plugin manager.
require("config.lazy")
