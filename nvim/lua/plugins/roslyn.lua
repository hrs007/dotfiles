-- C# support on Windows only.
if vim.fn.has("win32") ~= 1 then
    return {}
end

return {
    {
        "seblyng/roslyn.nvim",
        ft = { "cs" },
        opts = {},
    },
}
