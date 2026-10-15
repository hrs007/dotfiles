-- Shared build/run keys with project discovery based on the current file.
local Project = require("config.project")
local terminal_buffers = {}
local vite_server_buffers = {}
local is_windows = vim.fn.has("win32") == 1

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
    return buffer
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
    if is_windows and ft == "xml" and Project.find_csproj(current_start()) then
        return "cs"
    end
    if ft == "oil" then
        local start = current_start()
        if is_windows and Project.find_csproj(start) then return "cs" end
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
    local command = { "dotnet", "run", "--project", project, "--configuration", "Release" }
    local framework = Project.preferred_windows_framework(project)
    if framework then
        vim.list_extend(command, { "--framework", framework })
    end
    start_terminal(key, command, start)
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
        if Project.is_runnable_project(project) then
            run_dotnet_project(project, key .. ":" .. project, vim.fs.dirname(project))
            return
        end

        local runnable_projects = Project.find_runnable_projects(start)
        if #runnable_projects == 0 then
            notify("The current C# project is a library. No runnable app project was found in its solution.", vim.log.levels.ERROR)
            return
        end

        local function run_selected(selected)
            if selected then
                run_dotnet_project(selected, key .. ":" .. selected, vim.fs.dirname(selected))
            end
        end
        if #runnable_projects == 1 then
            run_selected(runnable_projects[1])
        else
            vim.ui.select(runnable_projects, {
                prompt = "Run C# app project",
                format_item = function(candidate)
                    return vim.fn.fnamemodify(candidate, ":~:.")
                end,
            }, run_selected)
        end
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

local function python_command(start)
    local root_marker = Project.find_upward(start, function(name)
        return name == "pyrightconfig.json" or name == "pyproject.toml"
            or name == "setup.py" or name == "setup.cfg" or name == "requirements.txt"
            or name == "Pipfile" or name == ".git"
    end)
    local root = root_marker and vim.fs.dirname(root_marker) or start
    local selected = require("config.python").resolve(root)
    if selected then
        return selected
    end

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
    local python = python_command(start)
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
    local python = python_command(start)
    if python == "" then
        notify("Python was not found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, { python, file }, start)
end

local function package_manager(package, data)
    local declared = data and data.packageManager
    if declared then
        local name = declared:match("^([%w_-]+)@")
        if name == "npm" or name == "pnpm" or name == "yarn" or name == "bun" then
            return name
        end
    end

    local root = package and vim.fs.dirname(package)
    local lockfile = root and Project.find_upward(root, function(name)
        return name == "pnpm-lock.yaml" or name == "yarn.lock"
            or name == "bun.lock" or name == "bun.lockb"
            or name == "package-lock.json" or name == "npm-shrinkwrap.json"
    end)
    if lockfile then
        local name = vim.fs.basename(lockfile)
        if name == "pnpm-lock.yaml" then return "pnpm" end
        if name == "yarn.lock" then return "yarn" end
        if name == "bun.lock" or name == "bun.lockb" then return "bun" end
        return "npm"
    end
    return "npm"
end

local function package_manager_command(manager)
    local windows = vim.fn.has("win32") == 1
    local candidates
    if windows and manager == "bun" then
        candidates = { "bun.exe", "bun.cmd", "bun" }
    elseif windows then
        candidates = { manager .. ".cmd", manager }
    else
        candidates = { manager }
    end
    for _, executable in ipairs(candidates) do
        local path = vim.fn.exepath(executable)
        if path ~= "" then
            return path
        end
    end
    return candidates[1]
end

local function run_package_script(manager, script)
    return { package_manager_command(manager), "run", script }
end

local function open_browser_preview(buffer)
    local url
    if buffer and vim.api.nvim_buf_is_valid(buffer) then
        local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
        for index = #lines, 1, -1 do
            local candidate = lines[index]:match("https?://[^%s]+")
            if candidate then
                url = candidate:gsub("[%]%)},;]+$", ""):gsub("%.$", "")
                break
            end
        end
    end

    local function open(url_to_open)
        if not url_to_open or url_to_open == "" then return end
        if not url_to_open:match("^https?://") then url_to_open = "http://" .. url_to_open end
        if vim.ui.open then
            local ok, err = pcall(vim.ui.open, url_to_open)
            if ok then return end
            notify("Could not open the browser preview: " .. tostring(err), vim.log.levels.ERROR)
            return
        end

        local opener = vim.fn.has("mac") == 1 and "open"
            or (vim.fn.has("win32") == 1 and "cmd.exe" or "xdg-open")
        local command = opener == "cmd.exe" and { opener, "/c", "start", "", url_to_open }
            or { opener, url_to_open }
        if vim.fn.executable(opener) ~= 1 then
            notify("No system browser opener was found.", vim.log.levels.ERROR)
            return
        end
        vim.fn.jobstart(command, { detach = true })
    end

    if url then
        open(url)
    else
        vim.ui.input({ prompt = "Preview URL", default = "http://localhost:5173" }, open)
    end
end

local function build_javascript(start, key)
    local package = Project.find_package_json(start)
    local data = Project.read_json(package)
    local script = data and data.scripts and data.scripts.build
    if not package or not script then
        notify("No build script was found in the nearest package.json.")
        return
    end
    local manager = package_manager(package, data)
    local command = package_manager_command(manager)
    if vim.fn.executable(command) ~= 1 then
        notify(manager .. " was not found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end
    vim.cmd("wall")
    start_terminal(key, run_package_script(manager, "build"), vim.fs.dirname(package))
end

local function run_javascript(file, start, key)
    local package = Project.find_package_json(start)
    local data = Project.read_json(package)
    local script = data and data.scripts and (data.scripts.start or data.scripts.dev)
    if script then
        local manager = package_manager(package, data)
        local command = package_manager_command(manager)
        if vim.fn.executable(command) ~= 1 then
            notify(manager .. " was not found on PATH.", vim.log.levels.ERROR)
            return
        end
        if focus_if_running(key) then return end
        vim.cmd("wall")
        start_terminal(key, run_package_script(manager, data.scripts.start and "start" or "dev"), vim.fs.dirname(package))
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

local function choose_package_script(start)
    local package = Project.find_package_json(start)
    local data = Project.read_json(package)
    local scripts = data and data.scripts
    if not package or type(scripts) ~= "table" then
        notify("No package.json scripts were found in this project.")
        return
    end

    local names = vim.tbl_keys(scripts)
    table.sort(names)
    if #names == 0 then
        notify("The nearest package.json has no scripts.")
        return
    end

    local manager = package_manager(package, data)
    local executable = package_manager_command(manager)
    if vim.fn.executable(executable) ~= 1 then
        notify(manager .. " was not found on PATH.", vim.log.levels.ERROR)
        return
    end

    vim.ui.select(names, {
        prompt = "Run " .. manager .. " script",
        format_item = function(name)
            return ("%-16s %s"):format(name, tostring(scripts[name]))
        end,
    }, function(script)
        if not script then return end
        local cwd = vim.fs.dirname(package)
        local key = "web-script:" .. package .. ":" .. script
        if focus_if_running(key) then return end
        vim.cmd("wall")
        start_terminal(key, run_package_script(manager, script), cwd)
    end)
end

local function choose_vite_server(start)
    local package = Project.find_package_json(start)
    local data = Project.read_json(package)
    local scripts = data and data.scripts
    if not package or type(scripts) ~= "table" then
        notify("No package.json was found for this web project.")
        return
    end

    local server_scripts = {}
    for name, command in pairs(scripts) do
        local command_text = tostring(command):lower()
        if name == "dev" or name == "start" or name == "serve"
            or (command_text:find("vite", 1, true) and not command_text:find("build", 1, true))
        then
            server_scripts[#server_scripts + 1] = name
        end
    end
    table.sort(server_scripts, function(a, b)
        local rank = { dev = 1, start = 2, serve = 3 }
        local ar, br = rank[a] or 4, rank[b] or 4
        if ar == br then return a < b end
        return ar < br
    end)
    if #server_scripts == 0 then
        notify("No dev, start, serve, or Vite script was found in package.json.")
        return
    end

    local key = "vite-server:" .. package
    local buffer = vite_server_buffers[key]
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        buffer = terminal_buffers[key]
        vite_server_buffers[key] = buffer
    end
    local job = buffer and vim.api.nvim_buf_is_valid(buffer) and vim.b[buffer].terminal_job_id
    local running = job and vim.fn.jobwait({ job }, 0)[1] == -1

    local choices = {}
    if running then
        choices = { "Open browser preview", "Focus running server", "Stop server", "Restart server" }
    else
        choices = { "Start dev server", "Open browser preview" }
        if buffer and vim.api.nvim_buf_is_valid(buffer) then
            table.insert(choices, "Reopen server terminal")
        end
    end

    vim.ui.select(choices, { prompt = "Vite / dev server · " .. vim.fn.fnamemodify(package, ":~:h") }, function(choice)
        if not choice then return end
        if choice == "Open browser preview" then
            open_browser_preview(buffer)
            return
        elseif choice == "Focus running server" then
            if not focus_if_running(key) then
                notify("The dev server is no longer running.", vim.log.levels.INFO)
            end
            return
        elseif choice == "Stop server" then
            if job then pcall(vim.fn.jobstop, job) end
            notify("Stopped the dev server. Its terminal output is available to reopen.", vim.log.levels.INFO)
            return
        elseif choice == "Reopen server terminal" then
            if not buffer or not vim.api.nvim_buf_is_valid(buffer) then return end
            local windows = vim.fn.win_findbuf(buffer)
            if #windows > 0 then
                vim.api.nvim_set_current_win(windows[1])
            else
                vim.cmd("botright 12sbuffer " .. buffer)
            end
            if job and vim.fn.jobwait({ job }, 0)[1] == -1 then vim.cmd("startinsert") end
            return
        end

        local function start(script)
            if not script then return end
            local manager = package_manager(package, data)
            local executable = package_manager_command(manager)
            if vim.fn.executable(executable) ~= 1 then
                notify(manager .. " was not found on PATH.", vim.log.levels.ERROR)
                return
            end

            local old_buffer = vite_server_buffers[key]
            local old_job = old_buffer and vim.api.nvim_buf_is_valid(old_buffer) and vim.b[old_buffer].terminal_job_id
            if old_job and vim.fn.jobwait({ old_job }, 0)[1] == -1 then pcall(vim.fn.jobstop, old_job) end
            if old_buffer and vim.api.nvim_buf_is_valid(old_buffer) then
                pcall(vim.api.nvim_buf_delete, old_buffer, { force = true })
            end
            terminal_buffers[key] = nil
            vite_server_buffers[key] = nil
            vim.cmd("wall")
            local new_buffer = start_terminal(key, run_package_script(manager, script), vim.fs.dirname(package))
            vite_server_buffers[key] = new_buffer
        end

        if #server_scripts == 1 then
            start(server_scripts[1])
        else
            vim.ui.select(server_scripts, {
                prompt = "Choose dev server script",
                format_item = function(name) return name .. "  ·  " .. tostring(scripts[name]) end,
            }, start)
        end
    end)
end

local native_targets = {}
local build_native_file

local function find_cmake_root(start)
    local cmake = Project.find_upward(start, function(name) return name == "CMakeLists.txt" end)
    return cmake and vim.fs.dirname(cmake) or nil
end

local function list_cmake_targets(build_dir)
    if vim.fn.isdirectory(build_dir) ~= 1 then
        return {}
    end

    local output = vim.fn.systemlist({ "cmake", "--build", build_dir, "--target", "help" })
    if vim.v.shell_error ~= 0 then
        return {}
    end

    local ignored = { all = true, clean = true, help = true, rebuild_cache = true, test = true }
    local found, seen = {}, {}
    for _, line in ipairs(output) do
        local target = line:match("^%.%.%.%s+([^%s]+)") or line:match("^%s*([^%s:]+):%s+phony")
        if target and not ignored[target] and not seen[target] then
            seen[target] = true
            table.insert(found, target)
        end
    end
    table.sort(found)
    return found
end

local function list_make_targets(makefile)
    local found, seen = {}, {}
    for _, line in ipairs(vim.fn.readfile(makefile)) do
        if not line:match("^%s") and not line:match("^#") then
            local target = line:match("^([^:#%%][^:]*):")
            if target then
                target = target:gsub("%s+$", "")
                if target ~= "" and not seen[target] then
                    seen[target] = true
                    table.insert(found, target)
                end
            end
        end
    end
    table.sort(found)
    return found
end

local function choose_target(root, kind, targets, prompt)
    if #targets == 0 then
        vim.ui.input({ prompt = prompt }, function(target)
            if target and target ~= "" then
                native_targets[root] = { kind = kind, target = target }
                notify("Build target set to " .. target, vim.log.levels.INFO)
            end
        end)
        return
    end

    vim.ui.select(targets, {
        prompt = "Build target  ·  " .. vim.fn.fnamemodify(root, ":~"),
        format_item = function(target)
            local current = native_targets[root]
            return target .. (current and current.target == target and "  (selected)" or "")
        end,
    }, function(target)
        if target then
            native_targets[root] = { kind = kind, target = target }
            notify("Build target set to " .. target, vim.log.levels.INFO)
        end
    end)
end

local function select_native_target(start, file)
    local root = find_cmake_root(start)
    if root then
        if vim.fn.executable("cmake") ~= 1 then
            notify("CMake was not found on PATH.", vim.log.levels.ERROR)
            return
        end
        local build_dir = root .. "/build"
        if vim.fn.isdirectory(build_dir) ~= 1 then
            notify("Configure the CMake project with Space b first, then choose its targets with Space c T.", vim.log.levels.INFO)
            return
        end
        choose_target(root, "cmake", list_cmake_targets(build_dir), "CMake target name: ")
        return
    end

    local makefile = Project.find_upward(start, function(name) return name == "Makefile" end)
    if makefile then
        root = vim.fs.dirname(makefile)
        choose_target(root, "make", list_make_targets(makefile), "Make target name: ")
        return
    end

    if file then
        root = vim.fs.dirname(file)
        native_targets[root] = { kind = "file", target = vim.fs.basename(file) }
        notify("Build target set to current source file.", vim.log.levels.INFO)
        return
    end
    notify("No CMakeLists.txt or Makefile found; choose a C/C++ source file first.", vim.log.levels.INFO)
end

local function build_native_target(start, file)
    local root = find_cmake_root(start)
    local selection = root and native_targets[root]

    if not root then
        local makefile = Project.find_upward(start, function(name) return name == "Makefile" end)
        root = makefile and vim.fs.dirname(makefile) or nil
        selection = root and native_targets[root]
    end

    if not root and file then
        root = vim.fs.dirname(file)
        selection = native_targets[root]
    end

    if not selection then
        select_native_target(start, file)
        return
    end

    if selection.kind == "file" then
        local selected_file = vim.fs.joinpath(root, selection.target)
        build_native_file(selected_file, root, "build-native-target:" .. root)
        return
    end
    local key = "build-native-target:" .. root
    if focus_if_running(key) then return end
    vim.cmd("wall")
    if selection.kind == "cmake" then
        start_terminal(key, {
            "cmake", "--build", root .. "/build", "--target", selection.target, "--config", "Release",
        }, root)
    else
        local make = vim.fn.exepath("make")
        if make == "" then make = "make" end
        start_terminal(key, { make, "-C", root, selection.target }, root)
    end
end

build_native_file = function(file, start, key)
    if not file then
        notify("Save the C/C++ source file before building it.")
        return
    end
    local is_c = vim.bo.filetype == "c" or vim.bo.filetype == "objc"
    local candidates = is_c and { "clang", "gcc", "cc" } or { "clang++", "g++", "c++" }
    local compiler
    for _, candidate in ipairs(candidates) do
        compiler = vim.fn.exepath(candidate)
        if compiler ~= "" then break end
    end
    if not compiler or compiler == "" then
        notify("No C/C++ compiler was found on PATH.", vim.log.levels.ERROR)
        return
    end
    if focus_if_running(key) then return end

    local build_dir = start .. package.config:sub(1, 1) .. "build"
    vim.fn.mkdir(build_dir, "p")
    local stem = vim.fn.fnamemodify(file, ":t:r")
    local output = vim.fs.joinpath(build_dir, stem .. (is_windows and ".exe" or ""))
    vim.cmd("wall")
    start_terminal(key, { compiler, "-g", "-O0", file, "-o", output }, start)
end

local function build_native(start, key, file)
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
                " -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON; if ($LASTEXITCODE -eq 0) { if (Test-Path " ..
                quote(build_dir .. "/compile_commands.json") .. ") { Copy-Item " ..
                quote(build_dir .. "/compile_commands.json") .. " " .. quote(root .. "/compile_commands.json") ..
                " -Force }; cmake --build " .. quote(build_dir) .. " --config Release }"
            start_terminal(key, { "powershell.exe", "-NoProfile", "-Command", script }, root)
        else
            local script = "cmake -S " .. vim.fn.shellescape(root) .. " -B " .. vim.fn.shellescape(build_dir) ..
                " -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cp " ..
                vim.fn.shellescape(build_dir .. "/compile_commands.json") .. " " ..
                vim.fn.shellescape(root .. "/compile_commands.json") .. " && cmake --build " ..
                vim.fn.shellescape(build_dir) .. " --config Release"
            start_terminal(key, { "sh", "-lc", script }, root)
        end
    elseif makefile then
        local root = vim.fs.dirname(makefile)
        local make = vim.fn.exepath("make")
        if make == "" then make = "make" end
        start_terminal(key, { make, "-C", root }, root)
    else
        build_native_file(file, start, key)
    end
end

local function workflow_root(ft, start)
    local marker
    if is_windows and ft == "cs" then
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
    if is_windows and ft == "cs" then
        build_csharp(start, key, false)
    elseif ft == "python" then
        build_python(current_file(), start, key)
    elseif ft == "javascript" or ft == "javascriptreact" or ft == "typescript" or ft == "typescriptreact" then
        build_javascript(start, key)
    elseif ft == "c" or ft == "cpp" or ft == "objc" or ft == "objcpp" then
        build_native(start, key, current_file())
    else
        notify("Build is not configured for filetype: " .. (ft ~= "" and ft or "unknown"))
    end
end

local function build_solution()
    local start = current_start()
    if not is_windows or current_filetype() ~= "cs" then
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
    if is_windows and ft == "cs" then
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

local function build_keymap_for_buffer(bufnr)
    local filetype = vim.api.nvim_buf_call(bufnr, current_filetype)
    local start = vim.api.nvim_buf_call(bufnr, current_start)
    local descriptions = {
        python = "Python: Check syntax",
        javascript = "Web: Build project",
        javascriptreact = "Web: Build project",
        typescript = "Web: Build project",
        typescriptreact = "Web: Build project",
        c = "C: Build project",
        cpp = "C++: Build project",
        objc = "C: Build project",
        objcpp = "C++: Build project",
    }
    if is_windows and filetype == "cs" then
        descriptions.cs = "C#: Build project"
    end

    local description = descriptions[filetype]
    if description then
        vim.keymap.set("n", "<leader>b", build, {
            buffer = bufnr,
            desc = description,
        })
    else
        pcall(vim.keymap.del, "n", "<leader>b", { buffer = bufnr })
    end

    local is_web = filetype == "javascript" or filetype == "javascriptreact"
        or filetype == "typescript" or filetype == "typescriptreact"
    if is_web then
        vim.keymap.set("n", "<leader>cN", function()
            choose_package_script(vim.api.nvim_buf_call(bufnr, current_start))
        end, { buffer = bufnr, desc = "Web: Run package script" })
        vim.keymap.set("n", "<leader>cA", function()
            require("config.code_actions").web_menu()
        end, { buffer = bufnr, desc = "Web: TypeScript / ESLint actions" })
        vim.keymap.set("n", "<leader>cV", function()
            choose_vite_server(vim.api.nvim_buf_call(bufnr, current_start))
        end, { buffer = bufnr, desc = "Web: Vite server controls" })
    else
        pcall(vim.keymap.del, "n", "<leader>cN", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<leader>cA", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<leader>cV", { buffer = bufnr })
    end

    local is_native = filetype == "c" or filetype == "cpp" or filetype == "objc" or filetype == "objcpp"
    if is_native then
        vim.keymap.set("n", "<leader>cT", function()
            select_native_target(current_start(), current_file())
        end, { buffer = bufnr, desc = "C/C++: Select build target" })
        vim.keymap.set("n", "<leader>cB", function()
            build_native_target(current_start(), current_file())
        end, { buffer = bufnr, desc = "C/C++: Build selected target" })
    else
        pcall(vim.keymap.del, "n", "<leader>cT", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<leader>cB", { buffer = bufnr })
    end
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    callback = function(event)
        build_keymap_for_buffer(event.buf)
    end,
})

if is_windows then
    vim.keymap.set("n", "<leader>B", build_solution, { desc = "Build C# solution" })
end
vim.keymap.set("n", "<leader>r", run, { desc = "Run current project or file" })

return {
    build = build,
    build_solution = build_solution,
    run = run,
    choose_package_script = choose_package_script,
    choose_vite_server = choose_vite_server,
}
