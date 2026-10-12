-- Extra WPF commands. Shared Build/Run keys are provided by language_workflow.
if vim.fn.has("win32") ~= 1 then
    return
end

local Project = require("config.project")
local terminal_buffers = {}
local last_build_terminal

local function paths(configuration)
    local start = Project.current_dir()
    local project = Project.find_csproj(start)
    if not project then
        vim.notify("No .csproj found in this directory or its parents.", vim.log.levels.ERROR)
        return
    end

    local content = Project.read_project(project) or ""
    local msbuild = Project.find_msbuild()
    local platform = content:find(configuration .. "|x64", 1, true) and "x64" or "AnyCPU"
    local solution = Project.find_solution(start) or project
    local root = vim.fs.dirname(solution)
    local output = Project.output_dir(project, configuration, platform)
    local executable = output .. "/" .. Project.assembly_name(project) .. ".exe"
    return root, solution, msbuild, executable, platform, output
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

local function build_target(configuration, task)
    local root, solution, msbuild, _, platform = paths(configuration)
    if not root then return end
    if not msbuild then
        vim.notify("MSBuild was not found. Install Visual Studio Build Tools or add MSBuild.exe to PATH.", vim.log.levels.ERROR)
        return
    end
    local key = task .. ":" .. configuration
    if focus_if_running(key) then return end
    vim.cmd("wall")
    local buffer = start_terminal(key, {
        msbuild,
        solution,
        "/t:" .. task,
        "/p:Configuration=" .. configuration,
        "/p:Platform=" .. platform,
    }, root)
    last_build_terminal = buffer
end

local function build(configuration)
    build_target(configuration, "Build")
end

local function clean(configuration)
    build_target(configuration, "Clean")
end

local function rebuild(configuration)
    build_target(configuration, "Rebuild")
end

local function run(configuration, arguments)
    local _, _, _, executable, _, output = paths(configuration)
    if not executable then return end
    if vim.fn.filereadable(executable) ~= 1 then
        vim.notify(configuration .. " executable not found. Build it first.", vim.log.levels.ERROR)
        return
    end

    local key = "Run:" .. configuration .. (arguments and ":args" or "")
    if focus_if_running(key) then
        vim.notify("That WPF instance is still running in its terminal.", vim.log.levels.INFO)
        return
    end

    local command = "& '" .. executable:gsub("'", "''") .. "'"
    if arguments and arguments ~= "" then
        command = command .. " " .. arguments
    end
    vim.cmd("wall")
    start_terminal(key, { "powershell.exe", "-NoProfile", "-Command", command }, output)
end

local function build_and_run(configuration)
    local root, solution, msbuild, executable, platform = paths(configuration)
    if not root then return end
    if not msbuild then
        vim.notify("MSBuild was not found. Install Visual Studio Build Tools or add MSBuild.exe to PATH.", vim.log.levels.ERROR)
        return
    end
    local key = "BuildRun:" .. configuration
    if focus_if_running(key) then return end
    local ps_quote = function(value)
        return "'" .. value:gsub("'", "''") .. "'"
    end
    local script = "$ErrorActionPreference = 'Stop'; & " .. ps_quote(msbuild) .. " " .. ps_quote(solution) ..
        " /t:Build /p:Configuration=" .. configuration .. " /p:Platform=" .. platform .. "; " ..
        "if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " ..
        "Push-Location -LiteralPath (Split-Path -LiteralPath " .. ps_quote(executable) .. "); & " ..
        ps_quote(executable) .. "; Pop-Location"
    vim.cmd("wall")
    last_build_terminal = start_terminal(key, { "powershell.exe", "-NoProfile", "-Command", script }, root)
end

local function open_output(configuration, external)
    local _, _, _, _, _, output = paths(configuration)
    if not output then return end
    if vim.fn.isdirectory(output) ~= 1 then
        vim.notify(configuration .. " output folder not found. Build it first.", vim.log.levels.WARN)
        return
    end
    if external then
        vim.fn.jobstart({ "explorer.exe", output }, { detach = true })
    else
        require("oil").open(output)
    end
end

local function open_solution()
    local start = Project.current_dir()
    local solution = Project.find_solution(start)
    if not solution then
        vim.notify("No .sln or .slnx found in this directory or its parents.", vim.log.levels.WARN)
        return
    end
    vim.cmd("edit " .. vim.fn.fnameescape(solution))
end

local function show_diagnostics()
    if not last_build_terminal or not vim.api.nvim_buf_is_valid(last_build_terminal) then
        vim.notify("No WPF build output is available yet.", vim.log.levels.WARN)
        return
    end
    vim.fn.setqflist({}, "r", {
        title = "WPF build diagnostics",
        lines = vim.api.nvim_buf_get_lines(last_build_terminal, 0, -1, false),
        efm = [[%f(%l\,%c): %t%*[^:]: %m,%f : %t%*[^:]: %m,%-G%.%#]],
    })
    if #vim.fn.getqflist() > 0 then
        vim.cmd("copen")
    else
        vim.notify("No compiler diagnostics found in the latest build output.", vim.log.levels.INFO)
    end
end

vim.keymap.set("n", "<leader>mb", function() build("Release") end, { desc = "WPF: Build Release x64" })
vim.keymap.set("n", "<leader>mc", function() clean("Release") end, { desc = "WPF: Clean Release x64" })
vim.keymap.set("n", "<leader>mx", function() build_and_run("Release") end, { desc = "WPF: Build and run Release x64" })
vim.keymap.set("n", "<leader>mr", function() run("Release") end, { desc = "WPF: Run Release x64" })
vim.keymap.set("n", "<leader>mD", function() build("Debug") end, { desc = "WPF: Build Debug x64" })
vim.keymap.set("n", "<leader>mR", function() run("Debug") end, { desc = "WPF: Run Debug x64" })
vim.keymap.set("n", "<leader>mX", function() build_and_run("Debug") end, { desc = "WPF: Build and run Debug x64" })
vim.keymap.set("n", "<leader>me", function() rebuild("Release") end, { desc = "WPF: Rebuild Release x64" })
vim.keymap.set("n", "<leader>mC", function() clean("Debug") end, { desc = "WPF: Clean Debug x64" })
vim.keymap.set("n", "<leader>mE", function() rebuild("Debug") end, { desc = "WPF: Rebuild Debug x64" })
vim.keymap.set("n", "<leader>mo", function() open_output("Release") end, { desc = "WPF: Open Release output" })
vim.keymap.set("n", "<leader>mO", function() open_output("Debug") end, { desc = "WPF: Open Debug output" })
vim.keymap.set("n", "<leader>mp", function() open_output("Release", true) end, { desc = "WPF: Show Release output in Explorer" })
vim.keymap.set("n", "<leader>mP", function() open_output("Debug", true) end, { desc = "WPF: Show Debug output in Explorer" })
vim.keymap.set("n", "<leader>ma", function()
    vim.ui.input({ prompt = "WPF Release arguments (PowerShell syntax): " }, function(args)
        if args ~= nil then run("Release", args) end
    end)
end, { desc = "WPF: Run Release with arguments" })
vim.keymap.set("n", "<leader>mA", function()
    vim.ui.input({ prompt = "WPF Debug arguments (PowerShell syntax): " }, function(args)
        if args ~= nil then run("Debug", args) end
    end)
end, { desc = "WPF: Run Debug with arguments" })
vim.keymap.set("n", "<leader>ms", open_solution, { desc = "WPF: Open solution" })
vim.keymap.set("n", "<leader>mq", show_diagnostics, { desc = "WPF: Show build diagnostics" })
