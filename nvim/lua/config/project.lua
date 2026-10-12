-- Project and tool discovery shared by language workflows.
local M = {}

local function current_dir()
    local name = vim.api.nvim_buf_get_name(0)
    if name:match("^oil://") then
        local ok, directory = pcall(function()
            return require("oil").get_current_dir()
        end)
        if ok and directory then
            return directory
        end
    end
    if name == "" or name:match("^term://") or name:match("^oil://") then
        return vim.fn.getcwd()
    end
    return vim.fs.dirname(name)
end

function M.current_dir()
    return current_dir()
end

function M.find_upward(start, predicate)
    return vim.fs.find(predicate, {
        path = start or current_dir(),
        upward = true,
    })[1]
end

function M.find_solution(start)
    local project = M.find_csproj(start)
    if project then
        local project_dir = vim.fs.dirname(project)
        local name = vim.fs.basename(project):gsub("%.csproj$", "")
        for _, extension in ipairs({ ".sln", ".slnx" }) do
            local candidate = project_dir .. "/" .. name .. extension
            if vim.fn.filereadable(candidate) == 1 then
                return candidate
            end
        end
    end
    local solutions = vim.fs.find(function(name)
        return name:match("%.slnx?$") ~= nil
    end, { path = start or current_dir(), upward = true })
    if project then
        local project_name = vim.fs.basename(project):lower()
        for _, solution in ipairs(solutions) do
            local content = table.concat(vim.fn.readfile(solution), "\n"):lower()
            if content:find(project_name, 1, true) then
                return solution
            end
        end
    end
    table.sort(solutions)
    return solutions[1]
end

function M.find_csproj(start)
    return M.find_upward(start, function(name)
        return name:match("%.csproj$") ~= nil
    end)
end

function M.read_project(project)
    if not project or vim.fn.filereadable(project) == 0 then
        return nil
    end
    return table.concat(vim.fn.readfile(project), "\n")
end

function M.is_sdk_project(project)
    local content = M.read_project(project) or ""
    return content:match("<Project[^>]-Sdk%s*=") ~= nil
        or (content:match("<TargetFrameworkVersion>") == nil
            and content:match("<TargetFrameworks?>") ~= nil)
end

function M.assembly_name(project)
    local content = M.read_project(project) or ""
    return content:match("<AssemblyName>%s*(.-)%s*</AssemblyName>")
        or vim.fs.basename(project):gsub("%.csproj$", "")
end

function M.output_type(project)
    local content = M.read_project(project) or ""
    return content:match("<OutputType>%s*(.-)%s*</OutputType>") or "Library"
end

function M.output_dir(project, configuration, platform)
    local content = M.read_project(project) or ""
    local expected = (configuration .. "|" .. platform):lower()
    for attributes, body in content:gmatch("<PropertyGroup([^>]*)>(.-)</PropertyGroup>") do
        local condition = attributes:match("Condition%s*=%s*['\"](.-)['\"]") or ""
        if condition:lower():find(expected, 1, true) then
            local output = body:match("<OutputPath>%s*(.-)%s*</OutputPath>")
            if output and output ~= "" then
                return vim.fs.normalize(vim.fs.dirname(project) .. "/" .. output)
            end
        end
    end
    return vim.fs.normalize(vim.fs.dirname(project) .. "/bin/" .. platform .. "/" .. configuration)
end

function M.find_msbuild()
    if vim.fn.has("win32") ~= 1 then
        return nil
    end

    local program_files_x86 = vim.env["ProgramFiles(x86)"]
    if program_files_x86 then
        local vswhere = program_files_x86 .. "\\Microsoft Visual Studio\\Installer\\vswhere.exe"
        if vim.fn.filereadable(vswhere) == 1 then
            local paths = vim.fn.systemlist({
                vswhere,
                "-latest",
                "-products",
                "*",
                "-requires",
                "Microsoft.Component.MSBuild",
                "-find",
                "MSBuild\\**\\Bin\\MSBuild.exe",
            })
            for _, path in ipairs(paths) do
                path = path:gsub("%s+$", "")
                if vim.fn.filereadable(path) == 1 then
                    return path
                end
            end
        end
    end

    local on_path = vim.fn.exepath("MSBuild.exe")
    if on_path ~= "" and vim.fn.filereadable(on_path) == 1 then
        return on_path
    end
    return nil
end

function M.find_package_json(start)
    return M.find_upward(start, function(name)
        return name == "package.json"
    end)
end

function M.read_json(path)
    if not path or vim.fn.filereadable(path) == 0 then
        return nil
    end
    local ok, value = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
    return ok and value or nil
end

return M
