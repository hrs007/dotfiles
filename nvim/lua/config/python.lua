-- Python environment selection shared by BasedPyright and the user picker.
local M = {}

local state_path = vim.fn.stdpath("state") .. "/python-interpreters.json"
local diagnostics_state_path = vim.fn.stdpath("state") .. "/python-diagnostics.json"
local selected_by_root = {}
local profile_by_root = {}

local diagnostic_profiles = {
    quiet = {
        label = "Quiet · core correctness checks",
        basedpyright = "off",
        -- Keep only fatal parse/IO failures and undefined names. Ruff's full
        -- F group also reports unused imports, shadowing, and other cleanup
        -- findings, which made Quiet unexpectedly noisy in larger files.
        ruff = { "E9", "F821" },
        description = "syntax and undefined-name checks; type checks disabled",
    },
    basic = {
        label = "Basic",
        basedpyright = "basic",
        ruff = { "E4", "E7", "E9", "F" },
        description = "common type, syntax, and Python correctness checks",
    },
    standard = {
        label = "Standard",
        basedpyright = "standard",
        ruff = { "E", "F" },
        description = "broader type checking and style checks",
    },
    strict = {
        label = "Strict",
        basedpyright = "strict",
        ruff = { "E", "F", "B", "UP" },
        description = "strict typing plus bug-prone and modernization rules",
    },
}

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

do
    local file = io.open(diagnostics_state_path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local ok, saved = pcall(vim.json.decode, content)
        if ok and type(saved) == "table" then
            profile_by_root = saved
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

function M.diagnostics_profile(root)
    local current_root = normalize(root or vim.fn.getcwd())
    -- Ruff and BasedPyright can choose different roots in the same project.
    -- Reuse the nearest saved project profile when one server's root is nested.
    local name = profile_by_root[current_root]
    if not name then
        local parent = vim.fs.dirname(current_root)
        while parent and parent ~= current_root do
            name = profile_by_root[parent]
            if name then
                break
            end
            current_root, parent = parent, vim.fs.dirname(parent)
        end
    end
    -- New projects use the quiet baseline; saved per-project choices continue
    -- to override it.
    name = name or "quiet"
    return name, diagnostic_profiles[name] or diagnostic_profiles.standard
end

local function ruff_settings(profile)
    return {
        -- Explicitly selected profiles should take effect even when a project
        -- has a Ruff config; users can still switch back to their own rules by
        -- selecting a profile that matches them.
        configurationPreference = "editorFirst",
        configuration = {
            lint = {
                select = vim.deepcopy(profile.ruff),
            },
        },
    }
end

function M.ruff_settings_for_root(root)
    local _, profile = M.diagnostics_profile(root)
    return ruff_settings(profile)
end

function M.apply_diagnostics_profile(root, profile_name, bufnr)
    root = normalize(root)
    local profile = diagnostic_profiles[profile_name]
    if not profile then
        vim.notify("Unknown Python diagnostics profile: " .. tostring(profile_name), vim.log.levels.ERROR)
        return false
    end

    profile_by_root[root] = profile_name
    vim.fn.mkdir(vim.fn.fnamemodify(diagnostics_state_path, ":h"), "p")
    local ok, encoded = pcall(vim.json.encode, profile_by_root)
    if not ok or vim.fn.writefile({ encoded }, diagnostics_state_path) ~= 0 then
        vim.notify("Could not save the Python diagnostics profile.", vim.log.levels.ERROR)
        return false
    end

    -- Use clients attached to this Python buffer. Ruff and BasedPyright may
    -- have different root markers, so exact root equality can silently skip
    -- one of them.
    local clients = bufnr and vim.lsp.get_clients({ bufnr = bufnr }) or vim.lsp.get_clients()
    local updated, restart_ruff = {}, false
    for _, client in ipairs(clients) do
        if client.name == "basedpyright" or client.name == "ruff" then
            if client.name == "basedpyright" then
                client.config.settings = vim.tbl_deep_extend(
                    "force",
                    client.config.settings or {},
                    { basedpyright = { analysis = { typeCheckingMode = profile.basedpyright } } }
                )
                client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                updated[#updated + 1] = client.name
            elseif client.name == "ruff" then
                local settings = ruff_settings(profile)
                client.config.init_options = vim.tbl_deep_extend(
                    "force",
                    client.config.init_options or {},
                    { settings = settings }
                )
                client:notify("workspace/didChangeConfiguration", {
                    settings = client.config.init_options.settings,
                })
                updated[#updated + 1] = client.name
                restart_ruff = true
            end
        end
    end

    -- Drop diagnostics produced by the previous rule set immediately. The
    -- servers republish with the selected settings (Ruff after its restart).
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        vim.diagnostic.reset(nil, bufnr)
    end

    -- Ruff reads its initialization settings when the server starts. Restart
    -- it after updating its cached config so the selected rule set is used
    -- immediately, including when a project has its own Ruff config file.
    if restart_ruff then
        vim.schedule(function()
            local ok = pcall(vim.cmd, "lsp restart ruff")
            if not ok then
                vim.notify(
                    "Ruff profile saved, but this Neovim version could not restart Ruff automatically. Run :lsp restart ruff.",
                    vim.log.levels.WARN
                )
            end
        end)
    end

    vim.notify(
        ("Python checks for %s: %s%s (%s)"):format(
            vim.fn.fnamemodify(root, ":~"),
            profile.label,
            #updated > 0 and (" · updated " .. table.concat(updated, ", ")) or " · saved for next LSP start",
            profile.description
        ),
        vim.log.levels.INFO
    )
    return true
end

function M.apply_diagnostics_profile_for_buffer(bufnr, profile_name)
    return M.apply_diagnostics_profile(project_root(bufnr), profile_name, bufnr)
end

function M.select_diagnostics_profile(bufnr)
    local root = project_root(bufnr)
    local choices = {}
    for name, profile in pairs(diagnostic_profiles) do
        choices[#choices + 1] = {
            name = name,
            label = profile.label .. "  ·  " .. profile.description,
        }
    end
    table.sort(choices, function(a, b)
        return a.name < b.name
    end)

    local current = M.diagnostics_profile(root)
    vim.ui.select(choices, {
        prompt = "Python diagnostics · " .. vim.fn.fnamemodify(root, ":~") .. " (current: " .. current .. ")",
        format_item = function(choice)
            return choice.label
        end,
    }, function(choice)
        if choice then
            M.apply_diagnostics_profile(root, choice.name, bufnr)
        end
    end)
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

vim.api.nvim_create_user_command("PythonDiagnosticsProfile", function(command)
    local bufnr = vim.api.nvim_get_current_buf()
    if command.args == "" then
        M.select_diagnostics_profile(bufnr)
        return
    end

    local root = project_root(bufnr)
    if not M.apply_diagnostics_profile(root, command.args:lower(), bufnr) then
        vim.notify("Choose one of: quiet, basic, standard, strict", vim.log.levels.INFO)
    end
end, {
    nargs = "?",
    complete = function()
        return { "quiet", "basic", "standard", "strict" }
    end,
    desc = "Choose Python diagnostics rules for this project",
})

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
