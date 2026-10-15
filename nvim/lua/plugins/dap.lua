return {
    {
        -- Core debugging engine.
        "mfussenegger/nvim-dap",

        dependencies = {
            -- Debugging interface.
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",

            -- Show variable values inline.
            "theHamsta/nvim-dap-virtual-text",

            -- Python debugging integration.
            "mfussenegger/nvim-dap-python",
        },

        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local Project = require("config.project")

            local map = vim.keymap.set
            local is_windows = vim.fn.has("win32") == 1
            local mason = vim.fn.stdpath("data") .. "/mason"

            local function find_coreclr_debugger()
                local debugger = vim.fn.exepath("netcoredbg")
                if debugger ~= "" then
                    return debugger
                end

                -- Reuse Microsoft's debugger when the C# tooling installed by
                -- VS Code is present; otherwise allow a standalone netcoredbg.
                local extension_roots = {
                    vim.fn.expand("~/.vscode/extensions"),
                    vim.fn.expand("~/.vscode-insiders/extensions"),
                }
                for _, root in ipairs(extension_roots) do
                    if vim.fn.isdirectory(root) == 1 then
                        for _, extension in ipairs(vim.fn.readdir(root)) do
                            local candidate = vim.fs.joinpath(
                                root,
                                extension,
                                "debugAdapters",
                                "vsdbg",
                                "bin",
                                "vsdbg.exe"
                            )
                            if vim.fn.filereadable(candidate) == 1 then
                                return candidate
                            end
                        end
                    end
                end
            end

            local coreclr_debugger = is_windows and find_coreclr_debugger() or nil
            if coreclr_debugger then
                dap.adapters.coreclr = {
                    type = "executable",
                    command = coreclr_debugger,
                    args = { "--interpreter=vscode" },
                }
                dap.configurations.cs = {
                    {
                        name = "Launch .NET app",
                        type = "coreclr",
                        request = "launch",
                        program = function()
                            return vim.fn.input("Path to .NET executable: ", vim.fn.getcwd() .. "\\bin\\Debug\\", "file")
                        end,
                        cwd = "${workspaceFolder}",
                        stopAtEntry = false,
                    },
                }
            end

            local function debug_maui_windows()
                if not coreclr_debugger then
                    vim.notify(
                        "No .NET debugger found. Install netcoredbg or the VS Code C# debugging tools.",
                        vim.log.levels.ERROR
                    )
                    return
                end

                local start = Project.current_dir()
                local current_project = Project.find_csproj(start)
                local candidates = {}
                if current_project and Project.is_runnable_project(current_project) then
                    candidates = { current_project }
                else
                    candidates = Project.find_runnable_projects(start)
                end

                if #candidates == 0 then
                    vim.notify("No runnable app project was found in this solution.", vim.log.levels.ERROR)
                    return
                end

                local function launch(project)
                    if not project then return end
                    local framework = Project.preferred_windows_framework(project)
                    vim.cmd("wall")
                    local command = { "dotnet", "build", project, "--configuration", "Debug" }
                    if framework then
                        vim.list_extend(command, { "--framework", framework })
                    end
                    vim.notify("Building the MAUI app in Debug configuration…", vim.log.levels.INFO)
                    vim.system(command, { cwd = vim.fs.dirname(project), text = true }, function(result)
                        vim.schedule(function()
                            if result.code ~= 0 then
                                local output = (result.stderr or "") .. "\n" .. (result.stdout or "")
                                local lines = vim.split(vim.trim(output), "\n")
                                local summary = table.concat(vim.list_slice(lines, math.max(1, #lines - 9)), "\n")
                                vim.notify("MAUI Debug build failed:\n" .. summary, vim.log.levels.ERROR, { title = "C# Debug" })
                                return
                            end

                            local executable = Project.find_built_executable(project, "Debug", framework)
                            if not executable or vim.fn.filereadable(executable) ~= 1 then
                                vim.notify("Build succeeded, but the Windows app executable was not found.", vim.log.levels.ERROR)
                                return
                            end

                            dap.run({
                                name = "Debug MAUI Windows app",
                                type = "coreclr",
                                request = "launch",
                                program = executable,
                                cwd = vim.fs.dirname(project),
                                stopAtEntry = false,
                                justMyCode = false,
                            })
                        end)
                    end)
                end

                if #candidates == 1 then
                    launch(candidates[1])
                else
                    vim.ui.select(candidates, {
                        prompt = "Choose app to debug",
                        format_item = function(project)
                            return vim.fn.fnamemodify(project, ":~:.")
                        end,
                    }, launch)
                end
            end

            map("n", "<leader>DM", debug_maui_windows, {
                desc = "Debug: Launch MAUI Windows app",
            })

            -- ==========================================
            -- Debug UI
            -- ==========================================

            dapui.setup()

            require("nvim-dap-virtual-text").setup()

            -- Open the UI when debugging starts.
            dap.listeners.after.event_initialized["dapui_config"] =
                function()
                    dapui.open()
                end

            -- Close the UI when debugging ends.
            dap.listeners.before.event_terminated["dapui_config"] =
                function()
                    dapui.close()
                end

            dap.listeners.before.event_exited["dapui_config"] =
                function()
                    dapui.close()
                end

            -- ==========================================
            -- Python Debugging: debugpy
            -- ==========================================

            local debugpy = mason
                .. "/packages/debugpy/venv/"
                .. (is_windows
                    and "Scripts/python.exe"
                    or "bin/python")

            require("dap-python").setup(debugpy)

            if vim.fn.executable(debugpy) ~= 1 then
                vim.notify(
                    "debugpy Python executable not found:\n"
                        .. debugpy
                        .. "\nInstall debugpy through :Mason.",
                    vim.log.levels.WARN
                )
            end

            -- ==========================================
            -- C/C++ Debugging: CodeLLDB
            -- ==========================================

            -- Prefer Mason's executable path when available.
            local codelldb = vim.fn.exepath("codelldb")

            -- Fall back to Mason's bin directory.
            if codelldb == "" then
                codelldb = mason
                    .. "/bin/codelldb"
                    .. (is_windows and ".cmd" or "")
            end

            if vim.fn.executable(codelldb) ~= 1 then
                vim.notify(
                    "CodeLLDB executable not found:\n"
                        .. codelldb
                        .. "\nInstall codelldb through :Mason.",
                    vim.log.levels.WARN
                )
            end

            dap.adapters.codelldb = {
                type = "server",
                port = "${port}",

                executable = {
                    command = codelldb,
                    args = {
                        "--port",
                        "${port}",
                    },
                },
            }

            -- ==========================================
            -- C/C++ Launch Configuration
            -- ==========================================

            local cpp_config = {
                {
                    name = "Launch C/C++ executable",
                    type = "codelldb",
                    request = "launch",

                    program = function()
                        local default_path = vim.fn.getcwd()
                            .. (is_windows and "\\" or "/")

                        return vim.fn.input(
                            "Executable path: ",
                            default_path,
                            "file"
                        )
                    end,

                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                    args = {},
                },
            }

            dap.configurations.c = cpp_config
            dap.configurations.cpp = cpp_config

            -- ==========================================
            -- JavaScript / TypeScript / Browser Debugging
            -- ==========================================

            local js_debug = mason .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
            local node = vim.fn.exepath("node")
            if node ~= "" then
                for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge" }) do
                    dap.adapters[adapter] = {
                        type = "server",
                        host = "127.0.0.1",
                        port = "${port}",
                        executable = {
                            command = node,
                            args = { js_debug, "${port}" },
                        },
                    }
                end

                local js_configurations = {
                    {
                        name = "Launch current file (Node)",
                        type = "pwa-node",
                        request = "launch",
                        program = "${file}",
                        cwd = "${workspaceFolder}",
                        sourceMaps = true,
                        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
                    },
                    {
                        name = "Launch browser (Vite / React)",
                        type = "pwa-chrome",
                        request = "launch",
                        url = function()
                            return vim.fn.input("App URL: ", "http://localhost:5173")
                        end,
                        webRoot = "${workspaceFolder}",
                        sourceMaps = true,
                        skipFiles = { "<node_internals>/**", "**/node_modules/**" },
                    },
                }

                for _, filetype in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
                    dap.configurations[filetype] = vim.deepcopy(js_configurations)
                end

                vim.api.nvim_create_autocmd("FileType", {
                    pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
                    callback = function(event)
                        vim.keymap.set("n", "<leader>Dj", function()
                            vim.cmd("wall")
                            dap.run(vim.deepcopy(js_configurations[2]))
                        end, {
                            buffer = event.buf,
                            desc = "Debug: Launch browser for web app",
                        })
                    end,
                })
            else
                vim.notify("Node.js is required to start the JavaScript debugger.", vim.log.levels.WARN)
            end

            -- ==========================================
            -- Debugging Keymaps
            -- ==========================================

            -- Start or continue debugging.
            -- Save all modified buffers first.
            map("n", "<leader>Dc", function()
                vim.cmd("wall")
                dap.continue()
            end, {
                desc = "Debug: Start or continue",
            })

            map("n", "<leader>Dn", dap.step_over, {
                desc = "Debug: Step over",
            })

            map("n", "<leader>Di", dap.step_into, {
                desc = "Debug: Step into",
            })

            map("n", "<leader>Do", dap.step_out, {
                desc = "Debug: Step out",
            })

            map("n", "<leader>Db", dap.toggle_breakpoint, {
                desc = "Debug: Toggle breakpoint",
            })

            map("n", "<leader>DB", function()
                dap.set_breakpoint(
                    vim.fn.input("Breakpoint condition: ")
                )
            end, {
                desc = "Debug: Conditional breakpoint",
            })

            map("n", "<leader>Du", dapui.toggle, {
                desc = "Debug: Toggle UI",
            })

            map("n", "<leader>Dr", dap.repl.open, {
                desc = "Debug: Open REPL",
            })

            map("n", "<leader>Dq", dap.terminate, {
                desc = "Debug: Terminate",
            })
        end,
    },
}
