-- Find filesystem routes in Next.js and path declarations used by React Router.
local M = {}
local Project = require("config.project")

local source_globs = {
    "*.js", "*.jsx", "*.ts", "*.tsx",
}
local excluded = {
    ".git", "node_modules", ".next", "dist", "build", "coverage", "vendor",
}

local function source_files(root)
    local rg = vim.fn.exepath("rg")
    if rg == "" then
        vim.notify("Route search needs ripgrep (rg).", vim.log.levels.ERROR)
        return {}
    end
    local command = { rg, "--files", "--hidden" }
    for _, directory in ipairs(excluded) do
        command[#command + 1] = "--glob"
        command[#command + 1] = "!**/" .. directory .. "/**"
    end
    for _, glob in ipairs(source_globs) do
        command[#command + 1] = "--glob"
        command[#command + 1] = glob
    end
    command[#command + 1] = root
    local files = vim.fn.systemlist(command)
    if vim.v.shell_error ~= 0 and #files == 0 then return {} end
    return files
end

local function route_path_from_file(relative)
    relative = relative:gsub("\\", "/")
    local prefix, tail
    for _, candidate in ipairs({ "src/app/", "app/" }) do
        if relative:sub(1, #candidate) == candidate then
            prefix, tail = candidate, relative:sub(#candidate + 1)
            break
        end
    end
    if prefix then
        if not (tail:match("^page%.[^/]+$") or tail:match("/page%.[^/]+$")) then return nil end
        tail = tail:gsub("page%.[^/]+$", ""):gsub("/$", "")
    else
        for _, candidate in ipairs({ "src/pages/", "pages/" }) do
            if relative:sub(1, #candidate) == candidate then
                prefix, tail = candidate, relative:sub(#candidate + 1)
                break
            end
        end
        if not prefix then return nil end
        tail = tail:gsub("%.[^./]+$", "")
        tail = tail:gsub("/index$", ""):gsub("^index$", "")
        if tail:match("^api/") or tail == "_app" or tail == "_document" or tail == "_error" then
            return nil
        end
    end

    local segments = {}
    for segment in tail:gmatch("[^/]+") do
        if segment:sub(1, 1) ~= "(" and segment:sub(1, 1) ~= "@" then
            local optional_catchall = segment:match("^%[%[%%.%.%.([%w_%-]+)%]%]$")
            local catchall = segment:match("^%[%%.%.%.([%w_%-]+)%]$")
            local parameter = segment:match("^%[([%w_%-]+)%]$")
            if optional_catchall then
                segments[#segments + 1] = "*" .. optional_catchall .. "?"
            elseif catchall then
                segments[#segments + 1] = "*" .. catchall
            elseif parameter then
                segments[#segments + 1] = ":" .. parameter
            else
                segments[#segments + 1] = segment
            end
        end
    end
    return "/" .. table.concat(segments, "/")
end

local function route_from_line(line)
    local path = line:match("path%s*=%s*\"([^\"]+)\"")
        or line:match("path%s*=%s*'([^']+)'")
        or line:match("path%s*:%s*\"([^\"]+)\"")
        or line:match("path%s*:%s*'([^']+)'")
    if not path then return nil end
    if path:find("${", 1, true) or path:match("^%w+%.") then return nil end
    return path
end

local function collect_routes(root)
    local routes, seen = {}, {}
    for _, file in ipairs(source_files(root)) do
        file = vim.fs.normalize(file)
        local relative = file:sub(#root + 2)
        local next_route = route_path_from_file(relative)
        if next_route then
            local key = next_route .. "\0" .. file
            seen[key] = true
            routes[#routes + 1] = { path = next_route, file = file, line = 1, source = "Next.js" }
        end

        local lines = vim.fn.readfile(file, "", 3000)
        for line_number, line in ipairs(lines) do
            if line:find("<Route", 1, true) or line:find("path", 1, true) then
                local path = route_from_line(line)
                if path then
                    local key = path .. "\0" .. file .. "\0" .. line_number
                    if not seen[key] then
                        seen[key] = true
                        routes[#routes + 1] = { path = path, file = file, line = line_number, source = "React Router" }
                    end
                end
            end
        end
    end
    table.sort(routes, function(a, b)
        if a.path == b.path then return a.file < b.file end
        return a.path < b.path
    end)
    return routes
end

local function open_routes()
    local start = Project.current_dir()
    local package = Project.find_upward(start, function(name) return name == "package.json" end)
    if not package then
        vim.notify("No package.json found for this web project.", vim.log.levels.INFO)
        return
    end
    local root = vim.fs.dirname(package)
    local routes = collect_routes(root)
    if #routes == 0 then
        vim.notify("No Next.js pages or React Router path declarations found.", vim.log.levels.INFO)
        return
    end

    vim.ui.select(routes, {
        prompt = "Pages and routes  ·  " .. vim.fn.fnamemodify(root, ":~"),
        format_item = function(route)
            local relative = route.file:gsub("^" .. vim.pesc(root .. package.config:sub(1, 1)), "")
            return ("%-16s %-13s %s"):format(route.path, route.source, relative)
        end,
    }, function(route)
        if not route then return end
        vim.cmd("edit " .. vim.fn.fnameescape(route.file))
        pcall(vim.api.nvim_win_set_cursor, 0, { route.line, 0 })
    end)
end

function M.setup()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        callback = function(event)
            vim.keymap.set("n", "<leader>cP", open_routes, {
                buffer = event.buf,
                desc = "Web: Find pages and routes",
            })
        end,
    })
end

return { setup = M.setup, open = open_routes }
