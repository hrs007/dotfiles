-- ==========================================
-- Bootstrap lazy.nvim
-- ==========================================

-- Get the directory where Neovim stores installed plugins.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Check whether lazy.nvim is already installed.
-- vim.uv is available in newer Neovim versions;
-- vim.loop provides compatibility with older versions.
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    -- Repository containing the lazy.nvim plugin manager.
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"

    -- Download lazy.nvim from its stable branch.
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        lazyrepo,
        lazypath,
    })

    -- Stop if Git failed to install the plugin manager.
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to install lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit...", "MoreMsg" },
        }, true, {})

        vim.fn.getchar()
        os.exit(1)
    end
end

-- Add lazy.nvim to Neovim's runtime path so it can be loaded.
vim.opt.rtp:prepend(lazypath)


-- ==========================================
-- Plugin Manager Configuration
-- ==========================================

require("lazy").setup({

    -- Automatically discover plugin specifications
    -- inside ~/.config/nvim/lua/plugins/.
    spec = {
        { import = "plugins" },
    },

    -- Use a built-in colorscheme if needed during installation.
    install = {
        colorscheme = { "habamax" },
    },

    -- Check for plugin updates periodically.
    checker = {
        enabled = true,
    },

    -- Disable optional LuaRocks integration.
    -- We can enable it later if a plugin actually requires it.
    rocks = {
        enabled = false,
    },
})
