-- C# support on Windows only.
if vim.fn.has("win32") ~= 1 then
    return {}
end

-- Always analyze open C# files for compiler and analyzer diagnostics. Roslyn
-- may otherwise retain an unset or project-inherited background scope.
vim.lsp.config("roslyn", {
    settings = {
        ["csharp|background_analysis"] = {
            dotnet_compiler_diagnostics_scope = "openFiles",
            dotnet_analyzer_diagnostics_scope = "openFiles",
        },
    },
})

return {
    {
        "seblyng/roslyn.nvim",
        ft = { "cs" },
        opts = {
            -- A solution may live above the current project folder or beside
            -- other child projects (for example, an .slnx repo layout).
            broad_search = true,
            -- Prefer the solution containing the current C# project when
            -- Roslyn discovers more than one solution in the repository.
            choose_target = function(targets)
                local Project = require("config.project")
                local solution = Project.find_solution(Project.current_dir())
                if not solution then return nil end
                local expected = vim.fs.normalize(solution):gsub("\\", "/"):lower()
                for _, target in ipairs(targets) do
                    if type(target) == "string"
                        and vim.fs.normalize(target):gsub("\\", "/"):lower() == expected
                    then
                        return target
                    end
                end
            end,
        },
    },
}
