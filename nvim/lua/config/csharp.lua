-- C# editing and test workflow.
local Project = require("config.project")

local function reload_roslyn()
    local clients = vim.lsp.get_clients({ name = "roslyn" })
    if #clients == 0 then
        vim.notify("Roslyn is not running for this workspace yet.", vim.log.levels.WARN)
        return
    end

    -- Roslyn can keep assembly metadata cached after a referenced DLL is
    -- replaced. Restart the server so it reopens the solution and reloads the
    -- project's references without requiring a full Neovim restart.
    local ok, err = pcall(vim.cmd, "lsp restart roslyn")
    if not ok then
        vim.notify("Could not restart Roslyn: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    vim.notify("Reloading C# solution and DLL references…", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("CSharpReloadReferences", reload_roslyn, {
    desc = "Reload Roslyn project and referenced DLLs",
})
vim.keymap.set("n", "<leader>cl", reload_roslyn, {
    desc = "C#: Reload solution and DLL references",
    silent = true,
})

local function open_location(path, line)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    vim.cmd("normal! zvzz")
end

local function search_declaration(symbol, bufnr)
    if not symbol:match("^[_%a][_%w]*$") then
        vim.notify("Roslyn returned no definition for this symbol.", vim.log.levels.WARN)
        return
    end

    local start = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    local solution = Project.find_solution(start)
    local project = Project.find_csproj(start)
    local root = solution and vim.fs.dirname(solution)
        or (project and vim.fs.dirname(project))
        or start
    local rg = vim.fn.exepath("rg")
    if rg == "" then
        vim.notify("Roslyn returned no definition, and ripgrep is unavailable for source fallback.", vim.log.levels.ERROR)
        return
    end

    local pattern = "\\b(class|struct|interface|record|enum)\\s+" .. symbol .. "\\b"
    vim.system({
        rg,
        "--line-number",
        "--no-heading",
        "--color",
        "never",
        "--glob",
        "*.cs",
        "--glob",
        "!**/obj/**",
        "--glob",
        "!**/bin/**",
        "-e",
        pattern,
        root,
    }, { text = true }, function(result)
        vim.schedule(function()
            local matches = {}
            for _, text in ipairs(vim.split(result.stdout or "", "\n", { trimempty = true })) do
                local path, line, source = text:match("^(.-):(%d+):(.*)$")
                if path and line then
                    matches[#matches + 1] = {
                        path = path,
                        line = tonumber(line),
                        source = vim.trim(source),
                    }
                end
            end

            if #matches == 0 then
                vim.notify(
                    "No C# declaration found for " .. symbol .. ". Check that the solution is loaded and restored.",
                    vim.log.levels.WARN
                )
                return
            end

            local function jump(match)
                if match then
                    open_location(match.path, match.line)
                end
            end
            if #matches == 1 then
                jump(matches[1])
            else
                vim.ui.select(matches, {
                    prompt = "C# source declarations for " .. symbol,
                    format_item = function(match)
                        return ("%s:%d · %s"):format(vim.fn.fnamemodify(match.path, ":t"), match.line, match.source)
                    end,
                }, jump)
            end
        end)
    end)
end

local function csharp_definition()
    local bufnr = vim.api.nvim_get_current_buf()
    local symbol = vim.fn.expand("<cword>")
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })
    if #clients == 0 then
        search_declaration(symbol, bufnr)
        return
    end

    local encoding = clients[1].offset_encoding or "utf-16"
    local params = vim.lsp.util.make_position_params(0, encoding)
    local finished = false
    vim.defer_fn(function()
        if not finished then
            finished = true
            search_declaration(symbol, bufnr)
        end
    end, 1500)
    local sent = vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result, context)
        if finished then return end
        finished = true
        local locations = result
        if type(result) == "table" and (result.uri or result.targetUri) then
            locations = { result }
        end
        if not err and type(locations) == "table" and #locations > 0 then
            local client = vim.lsp.get_client_by_id(context.client_id)
            local client_encoding = client and client.offset_encoding or encoding
            if #locations == 1 then
                vim.lsp.util.show_document(locations[1], client_encoding, {
                    focus = true,
                    reuse_win = true,
                })
            else
                local items = vim.lsp.util.locations_to_items(locations, client_encoding)
                vim.fn.setqflist({}, " ", { title = "C# definitions", items = items })
                vim.cmd("copen")
            end
            return
        end
        search_declaration(symbol, bufnr)
    end)
    if not sent then
        if not finished then
            finished = true
            search_declaration(symbol, bufnr)
        end
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function(event)
        local opts = { buffer = event.buf, silent = true }
        local file_dir = Project.current_dir()

        vim.keymap.set("n", "gd", csharp_definition, vim.tbl_extend("force", opts, {
            desc = "C#: Go to definition (Roslyn, with source fallback)",
        }))

        vim.keymap.set("n", "<leader>ci", function()
            vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
            })
        end, vim.tbl_extend("force", opts, { desc = "C#: Organize usings" }))

        vim.keymap.set("n", "<leader>cf", function()
            require("conform").format({
                bufnr = event.buf,
                async = false,
                lsp_format = "prefer",
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
