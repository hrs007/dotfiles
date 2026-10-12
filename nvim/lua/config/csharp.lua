-- C# editing and test workflow.
local Project = require("config.project")

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function(event)
        local opts = { buffer = event.buf, silent = true }
        local file_dir = Project.current_dir()

        vim.keymap.set("n", "<leader>ci", function()
            vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
            })
        end, vim.tbl_extend("force", opts, { desc = "C#: Organize usings" }))

        vim.keymap.set("n", "<leader>cf", function()
            require("conform").format({
                bufnr = event.buf,
                async = false,
                lsp_format = "never",
            })
        end, vim.tbl_extend("force", opts, { desc = "C#: Format file" }))

        vim.keymap.set("n", "<leader>cp", function()
            local project = Project.find_csproj(file_dir)
            if not project then
                vim.notify("No .csproj found in this directory or its parents.", vim.log.levels.WARN)
                return
            end
            vim.cmd("edit " .. vim.fn.fnameescape(project))
        end, vim.tbl_extend("force", opts, { desc = "C#: Open project file" }))

        vim.keymap.set("n", "<leader>cS", function()
            require("telescope.builtin").lsp_document_symbols()
        end, vim.tbl_extend("force", opts, { desc = "C#: Find symbols in file" }))

        vim.keymap.set("n", "<leader>ct", function()
            local solution = Project.find_solution(file_dir)
            if not solution then
                vim.notify("No .sln or .slnx found in this directory or its parents.", vim.log.levels.WARN)
                return
            end
            if vim.fn.executable("dotnet") ~= 1 then
                vim.notify("dotnet CLI was not found on PATH.", vim.log.levels.ERROR)
                return
            end

            local test_buf = vim.b[event.buf].dotnet_test_terminal
            if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
                local job = vim.b[test_buf].terminal_job_id
                if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
                    local windows = vim.fn.win_findbuf(test_buf)
                    if #windows > 0 then
                        vim.api.nvim_set_current_win(windows[1])
                    else
                        vim.cmd("botright 12sbuffer " .. test_buf)
                    end
                    vim.cmd("startinsert")
                    return
                end
            end

            vim.cmd("botright 12new")
            local terminal = vim.api.nvim_get_current_buf()
            vim.b[event.buf].dotnet_test_terminal = terminal
            vim.fn.termopen({ "dotnet", "test", solution }, {
                cwd = vim.fs.dirname(solution),
            })
            vim.cmd("startinsert")
        end, vim.tbl_extend("force", opts, { desc = "C#: Test solution" }))
    end,
})
