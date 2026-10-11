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

            -- Configure the debugging interface.
            dapui.setup()

            -- Show variable values inline.
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

            -- Python debugger: debugpy installed through Mason.
            local debugpy = vim.fn.stdpath("data")
                .. "/mason/packages/debugpy/venv/bin/python"

            require("dap-python").setup(debugpy)

            -- C/C++ debugger: CodeLLDB installed through Mason.
            local codelldb = vim.fn.stdpath("data")
                .. "/mason/bin/codelldb"

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

            -- Configuration shared by C and C++.
            local cpp_config = {
                {
                    name = "Launch C/C++ executable",
                    type = "codelldb",
                    request = "launch",

                    program = function()
                        return vim.fn.input(
                            "Executable path: ",
                            vim.fn.getcwd() .. "/",
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

            -- Debugging keymaps.
            local map = vim.keymap.set

            map("n", "<leader>Dc", function()
                -- Save all modified buffers before debugging
                vim.cmd("wall")

                -- Start or continue debugging
                dap.continue()
            end, { desc = "Debug: Start or continue" })

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
