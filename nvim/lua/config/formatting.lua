-- Global format-on-save preference, shared by every project and Neovim session.
local M = {}

local state_path = vim.fs.joinpath(vim.fn.stdpath("state"), "format-on-save.json")
local enabled = true

do
    if vim.fn.filereadable(state_path) == 1 then
        local lines = vim.fn.readfile(state_path)
        local ok, saved = pcall(vim.json.decode, table.concat(lines, "\n"))
        if ok and type(saved) == "table" and type(saved.enabled) == "boolean" then
            enabled = saved.enabled
        end
    end
end

function M.is_enabled()
    return enabled
end

function M.toggle()
    enabled = not enabled
    vim.fn.mkdir(vim.fs.dirname(state_path), "p")
    local ok, result = pcall(vim.fn.writefile, {
        vim.json.encode({ enabled = enabled }),
    }, state_path)
    if not ok or result ~= 0 then
        vim.notify("Could not save format-on-save preference: " .. tostring(result), vim.log.levels.ERROR)
        return
    end

    vim.notify("Format on save " .. (enabled and "enabled" or "disabled") .. " for all projects")
end

function M.format_on_save(bufnr)
    if not enabled then
        return
    end

    -- Roslyn formatting can take long enough to make a synchronous write feel
    -- stuck. C# is handled by Conform's asynchronous format_after_save hook.
    if vim.bo[bufnr].filetype == "cs" then
        return
    end

    return {
        timeout_ms = 5000,
        -- C# uses Roslyn, matching Visual Studio. XML uses the attached XML
        -- language server; other files use their configured external formatter.
        lsp_format = vim.bo[bufnr].filetype == "cs" and "prefer"
            or (vim.bo[bufnr].filetype == "xml" and "fallback" or "never"),
    }
end

function M.format_after_save(bufnr)
    if not enabled or vim.bo[bufnr].filetype ~= "cs" then
        return
    end

    return {
        timeout_ms = 10000,
        lsp_format = "prefer",
    }
end

vim.api.nvim_create_user_command("FormatOnSaveToggle", M.toggle, {
    desc = "Toggle format on save for all projects",
})

return M
