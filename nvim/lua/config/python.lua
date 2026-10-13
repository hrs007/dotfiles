-- Python environment selection shared by BasedPyright and the user picker.
local M = {}

local state_path = vim.fn.stdpath("state") .. "/python-interpreters.json"
local selected_by_root = {}

do
    local file = io.open(state_path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local ok, saved = pcall(vim.json.decode, content)
        if ok and type(saved) == "table" then
            selected_by_root = saved
        end
    end
end

local function normalize(path)
    return vim.fs.normalize(vim.fn.expand(path))
end

local function interpreter_for_environment(environment)
    local separator = package.config:sub(1, 1)
    local paths = separator == "\\"
            and { "Scripts/python.exe", "Scripts/python" }
        or { "bin/python", "bin/python3" }

    for _, relative in ipairs(paths) do
        local interpreter = vim.fs.joinpath(environment, relative)
        if vim.fn.executable(interpreter) == 1 then
            return interpreter
        end
    end
end

local function project_root(bufnr)
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = "basedpyright" })[1]
    if client and client.config.root_dir then
        return normalize(client.config.root_dir)
    end

    local file = vim.api.nvim_buf_get_name(bufnr)
    if file ~= "" then
        return normalize(vim.fs.root(file, {
            "pyrightconfig.json",
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            ".git",
        }) or vim.fs.dirname(file))
    end
    return normalize(vim.fn.getcwd())
end

function M.resolve(root)
    if not root or root == "" then
        return nil
    end
    root = normalize(root)
    local selected = selected_by_root[root]
    if selected and vim.fn.executable(selected) == 1 then
        return selected
    end

    -- uv's default project environment is .venv. Also honor its override and
    -- common venv names so opening a project usually needs no manual selection.
    local environments = {}
    local uv_environment = vim.env.UV_PROJECT_ENVIRONMENT
    if uv_environment and uv_environment ~= "" then
        table.insert(environments, vim.fs.is_absolute(uv_environment)
            and normalize(uv_environment)
            or vim.fs.joinpath(root, uv_environment))
    end
    for _, name in ipairs({ ".venv", "venv", "env", "ENV" }) do
        table.insert(environments, vim.fs.joinpath(root, name))
    end

    local active = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
    if active and active ~= "" then
        table.insert(environments, normalize(active))
    end

    for _, environment in ipairs(environments) do
        local interpreter = interpreter_for_environment(environment)
        if interpreter then
            return interpreter
        end
    end
end

function M.environment_for_buffer(bufnr)
    local root = project_root(bufnr)
    local interpreter = M.resolve(root)
    if not interpreter then
        return nil
    end

    local environment = vim.fs.dirname(vim.fs.dirname(normalize(interpreter)))
    if vim.fn.filereadable(vim.fs.joinpath(environment, "pyvenv.cfg")) == 1
        or vim.fn.isdirectory(vim.fs.joinpath(environment, "conda-meta")) == 1 then
        return environment
    end
end

local function remember(root, interpreter)
    selected_by_root[root] = interpreter
    vim.fn.mkdir(vim.fn.fnamemodify(state_path, ":h"), "p")
    local ok, encoded = pcall(vim.json.encode, selected_by_root)
    if ok then
        vim.fn.writefile({ encoded }, state_path)
    end
end

local function apply_to_project(root, interpreter)
    for _, client in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
        if client.config.root_dir and normalize(client.config.root_dir) == root then
            client.config.settings = vim.tbl_deep_extend(
                "force",
                client.config.settings or {},
                { python = { pythonPath = interpreter } }
            )
            client:notify("workspace/didChangeConfiguration", {
                settings = client.config.settings,
            })
        end
    end
end

local function select_interpreter(bufnr)
    local root = project_root(bufnr)
    local choices, seen = {}, {}

    local function add(interpreter, label)
        if interpreter and vim.fn.executable(interpreter) == 1 then
            interpreter = normalize(interpreter)
            if not seen[interpreter] then
                seen[interpreter] = true
                table.insert(choices, { path = interpreter, label = label or interpreter })
            end
        end
    end

    for _, environment in ipairs({
        vim.env.VIRTUAL_ENV,
        vim.env.CONDA_PREFIX,
        vim.env.UV_PROJECT_ENVIRONMENT,
        vim.fs.joinpath(root, ".venv"),
        vim.fs.joinpath(root, "venv"),
        vim.fs.joinpath(root, "env"),
        vim.fs.joinpath(root, "ENV"),
    }) do
        if environment and environment ~= "" then
            local resolved = vim.fs.is_absolute(environment)
                    and normalize(environment)
                or vim.fs.joinpath(root, environment)
            local interpreter = interpreter_for_environment(resolved)
            add(interpreter, vim.fs.basename(resolved) .. "  ·  " .. resolved)
        end
    end

    local current = selected_by_root[root] or M.resolve(root)
    add(current, current and ("Current  ·  " .. current))
    table.insert(choices, { browse = true, label = "Enter interpreter or environment path…" })

    vim.ui.select(choices, {
        prompt = "Python interpreter  ·  " .. vim.fn.fnamemodify(root, ":~"),
        format_item = function(item)
            return item.label
        end,
    }, function(choice)
        if not choice then
            return
        end
        if choice.browse then
            vim.ui.input({ prompt = "Python interpreter or environment path: ", completion = "file" }, function(path)
                if not path or path == "" then
                    return
                end
                path = normalize(path)
                local interpreter = vim.fn.isdirectory(path) == 1 and interpreter_for_environment(path) or path
                if not interpreter or vim.fn.executable(interpreter) ~= 1 then
                    vim.notify("That path does not contain an executable Python interpreter.", vim.log.levels.ERROR)
                    return
                end
                remember(root, normalize(interpreter))
                apply_to_project(root, normalize(interpreter))
                vim.notify("Python interpreter set to " .. normalize(interpreter), vim.log.levels.INFO)
            end)
            return
        end

        remember(root, choice.path)
        apply_to_project(root, choice.path)
        vim.notify("Python interpreter set to " .. choice.path, vim.log.levels.INFO)
    end)
end

vim.api.nvim_create_user_command("PythonSelectInterpreter", function()
    select_interpreter(vim.api.nvim_get_current_buf())
end, { desc = "Choose the Python interpreter for this project" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function(event)
        vim.keymap.set("n", "<leader>cp", "<Cmd>PythonSelectInterpreter<CR>", {
            buffer = event.buf,
            desc = "Python: Select interpreter",
        })
    end,
})

return M
