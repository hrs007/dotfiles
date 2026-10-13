-- Shared build/run keys with project discovery based on the current file.
local Project = require("config.project")
local terminal_buffers = {}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.WARN)
end

local function focus_if_running(key)
    local buffer = terminal_buffers[key]
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        return false
    end
    local job = vim.b[buffer].terminal_job_id
    if not job or vim.fn.jobwait({ job }, 0)[1] ~= -1 then
        return false
    end

    local windows = vim.fn.win_findbuf(buffer)
    if #windows > 0 then
        vim.api.nvim_set_current_win(windows[1])
    else
        vim.cmd("botright 12sbuffer " .. buffer)
    end
    vim.cmd("startinsert")
    return true
end

local function start_terminal(key, command, cwd)
    vim.cmd("botright 12new")
    local buffer = vim.api.nvim_get_current_buf()
    terminal_buffers[key] = buffer
    vim.fn.termopen(command, { cwd = cwd })
    vim.cmd("startinsert")
end

local function current_file()
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" or file:match("^term://") or file:match("^oil://") then
        return nil
    end
    return vim.fs.normalize(file)
end

local function current_start()
    local file = current_file()
    return file and vim.fs.dirname(file) or Project.current_dir()
end

local function current_filetype()
    local ft = vim.bo.filetype
    if ft == "xml" and Project.find_csproj(current_start()) then
        return "cs"
    end
    if ft == "oil" then
        local start = current_start()
        if Project.find_csproj(start) then return "cs" end
        if Project.find_package_json(start) then return "javascript" end
        if Project.find_upward(start, function(name)
            return name == "pyproject.toml" or name == "setup.py"
        end) then
            return "python"
        end
        if Project.find_upward(start, function(name)
            return name == "CMakeLists.txt" or name == "Makefile"
        end) then
            return "cpp"
        end
    end
    return ft
end

local function run_dotnet_project(project, key, start)
    if vim.fn.executable("dotnet") ~= 1 then
        notify("dotnet CLI was not found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, { "dotnet", "run", "--project", project, "--configuration", "Release" }, start)
end

local function build_csharp(start, key, build_solution)
    local project = Project.find_csproj(start)
    if not project then
        notify("No .csproj found in this directory or its parents.")
        return
    end

    -- Build only the project containing the current file by default. A solution
    -- build is available separately for users who want all projects together.
    local target = project
    if build_solution then
        target = Project.find_solution(start) or project
    end

    if Project.is_sdk_project(project) then
        if vim.fn.executable("dotnet") ~= 1 then
            notify("dotnet CLI was not found on PATH.", vim.log.levels.ERROR)
            return
        end
        if focus_if_running(key) then return end
        vim.cmd("wall")
        start_terminal(key, { "dotnet", "build", target, "--configuration", "Release" }, vim.fs.dirname(target))
        return
    end

    local msbuild = Project.find_msbuild()
    if not msbuild then
        notify("MSBuild was not found. Install Visual Studio Build Tools or add MSBuild.exe to PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end

    local content = Project.read_project(project) or ""
    local platform = content:find("Release|x64", 1, true) and "x64" or "AnyCPU"
    vim.cmd("wall")
    start_terminal(key, {
        msbuild,
        target,
        "/t:Build",
        "/p:Configuration=Release",
        "/p:Platform=" .. platform,
    }, vim.fs.dirname(target))
end

local function run_csharp(start, key)
    local project = Project.find_csproj(start)
    if not project then
        notify("No .csproj found in this directory or its parents.")
        return
    end

    if Project.is_sdk_project(project) then
        run_dotnet_project(project, key, vim.fs.dirname(project))
        return
    end

    if vim.fn.has("win32") ~= 1 then
        notify("Running this .NET Framework project requires Windows.", vim.log.levels.ERROR)
        return
    end
    local content = Project.read_project(project) or ""
    local platform = content:find("Release|x64", 1, true) and "x64" or "AnyCPU"
    local output = Project.output_dir(project, "Release", platform)
    local executable = output .. "/" .. Project.assembly_name(project) .. ".exe"
    if vim.fn.filereadable(executable) ~= 1 then
        notify("Release executable not found. Build the project first.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    local quoted = "'" .. executable:gsub("'", "''") .. "'"
    start_terminal(key, { "powershell.exe", "-NoProfile", "-Command", "& " .. quoted }, output)
end

local function python_command()
    local exe = vim.fn.exepath("python")
    if exe == "" then exe = vim.fn.exepath("python3") end
    if exe == "" then exe = vim.fn.exepath("py") end
    return exe
end

local function build_python(file, start, key)
    if not file then
        notify("Save the Python file before compiling it.")
        return
    end
    local python = python_command()
    if python == "" then
        notify("Python was not found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, { python, "-m", "py_compile", file }, start)
end

local function run_python(file, start, key)
    if not file then
        notify("Save the Python file before running it.")
        return
    end
    local python = python_command()
    if python == "" then
        notify("Python was not found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, { python, file }, start)
end

local function npm_command()
    if vim.fn.has("win32") == 1 then
        return vim.fn.exepath("npm.cmd") ~= "" and vim.fn.exepath("npm.cmd") or "npm.cmd"
    end
    return vim.fn.exepath("npm") ~= "" and vim.fn.exepath("npm") or "npm"
end

local function build_javascript(start, key)
    local package = Project.find_package_json(start)
    local data = Project.read_json(package)
    local script = data and data.scripts and data.scripts.build
    if not package or not script then
        notify("No npm build script was found in the nearest package.json.")
        return
    end
    if vim.fn.executable(npm_command()) ~= 1 then
        notify("npm was not found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, { npm_command(), "run", "build" }, vim.fs.dirname(package))
end

local function run_javascript(file, start, key)
    local package = Project.find_package_json(start)
    local data = Project.read_json(package)
    local script = data and data.scripts and (data.scripts.start or data.scripts.dev)
    if script then
        if vim.fn.executable(npm_command()) ~= 1 then
            notify("npm was not found on PATH.", vim.log.levels.ERROR)
            return
        end
        if focus_if_running(key) then return end
        vim.cmd("wall")
        start_terminal(key, { npm_command(), "run", data.scripts.start and "start" or "dev" }, vim.fs.dirname(package))
        return
    end
    if vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact" then
        notify("No start/dev script found. Add one to package.json to run this TypeScript project.")
        return
    end
    if not file or vim.fn.executable("node") ~= 1 then
        notify("Node.js was not found, or the current file has not been saved.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, { "node", file }, package and vim.fs.dirname(package) or start)
end

local function build_native(start, key)
    local cmake = Project.find_upward(start, function(name) return name == "CMakeLists.txt" end)
    local makefile = Project.find_upward(start, function(name) return name == "Makefile" end)
    if focus_if_running(key) then return end
    vim.cmd("wall")
    if cmake then
        local root = vim.fs.dirname(cmake)
        if vim.fn.executable("cmake") ~= 1 then
            notify("CMake was not found on PATH.", vim.log.levels.ERROR)
            return
        end
        local build_dir = root .. "/build"
        if vim.fn.has("win32") == 1 then
            local quote = function(value) return "'" .. value:gsub("'", "''") .. "'" end
            local script = "cmake -S " .. quote(root) .. " -B " .. quote(build_dir) ..
                " -DCMAKE_BUILD_TYPE=Release; if ($LASTEXITCODE -eq 0) { cmake --build " ..
                quote(build_dir) .. " --config Release }"
            start_terminal(key, { "powershell.exe", "-NoProfile", "-Command", script }, root)
        else
            local script = "cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(build_dir) ..
                " -DCMAKE_BUILD_TYPE=Release && cmake --build " .. vim.fn.shellescape(build_dir) .. " --config Release"
            start_terminal(key, { "sh", "-lc", script }, root)
        end
    elseif makefile then
        local root = vim.fs.dirname(makefile)
        local make = vim.fn.exepath("make")
        if make == "" then make = "make" end
        start_terminal(key, { make, "-C", root }, root)
    else
        notify("No CMakeLists.txt or Makefile found in this directory or its parents.")
    end
end

local function workflow_root(ft, start)
    local marker
    if ft == "cs" then
        marker = Project.find_csproj(start)
    elseif ft == "python" then
        marker = Project.find_upward(start, function(name)
            return name == "pyproject.toml" or name == "setup.py"
        end)
    elseif ft == "javascript" or ft == "javascriptreact" or ft == "typescript" or ft == "typescriptreact" then
        marker = Project.find_package_json(start)
    elseif ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" then
        marker = Project.find_upward(start, function(name)
            return name == "CMakeLists.txt" or name == "Makefile"
        end)
    end
    return marker and vim.fs.dirname(marker) or start
end

local function run_native(start, key)
    vim.ui.input({ prompt = "Executable to run: ", default = start .. package.config:sub(1, 1) }, function(executable)
        if not executable or executable == "" then return end
        if vim.fn.filereadable(executable) ~= 1 then
            notify("That executable path does not exist.", vim.log.levels.ERROR)
            return
        end
        if focus_if_running(key) then return end
        vim.cmd("wall")
        start_terminal(key, { executable }, vim.fs.dirname(executable))
    end)
end

local function build()
    local start = current_start()
    local ft = current_filetype()
    local key = "build:" .. workflow_root(ft, start)
    if ft == "cs" then
        build_csharp(start, key, false)
    elseif ft == "python" then
        build_python(current_file(), start, key)
    elseif ft == "javascript" or ft == "javascriptreact" or ft == "typescript" or ft == "typescriptreact" then
        build_javascript(start, key)
    elseif ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" then
        build_native(start, key)
    else
        notify("Build is not configured for filetype: " .. (ft ~= "" and ft or "unknown"))
    end
end

local function build_solution()
    local start = current_start()
    if current_filetype() ~= "cs" then
        notify("Solution builds are available from a C# project.")
        return
    end
    local solution = Project.find_solution(start)
    if not solution then
        notify("No solution found; building the current project instead.", vim.log.levels.INFO)
    end
    local key = "build-solution:" .. (solution or Project.find_csproj(start) or start)
    build_csharp(start, key, true)
end

local function run()
    local start = current_start()
    local file = current_file()
    local ft = current_filetype()
    local key = "run:" .. workflow_root(ft, start)
    if ft == "cs" then
        run_csharp(start, key)
    elseif ft == "python" then
        run_python(file, start, key)
    elseif ft == "javascript" or ft == "javascriptreact" or ft == "typescript" or ft == "typescriptreact" then
        run_javascript(file, start, key)
    elseif ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" then
        run_native(start, key)
    else
        notify("Run is not configured for filetype: " .. (ft ~= "" and ft or "unknown"))
    end
end

vim.keymap.set("n", "<leader>b", build, { desc = "Build current project" })
vim.keymap.set("n", "<leader>B", build_solution, { desc = "Build C# solution" })
vim.keymap.set("n", "<leader>r", run, { desc = "Run current project or file" })

return {
    build = build,
    build_solution = build_solution,
    run = run,
}
