local M = {}

function M.pick()
    local cache_path = vim.fn.stdpath("cache") .. "/dashboard/cache"
    local ok, projects = pcall(require("dashboard.utils").read_project_cache, cache_path)
    if not ok or type(projects) ~= "table" or #projects == 0 then
        vim.notify("No recent projects yet", vim.log.levels.INFO)
        return
    end

    projects = vim.tbl_filter(function(path)
        return type(path) == "string" and vim.fn.isdirectory(path) == 1
    end, projects)

    if #projects == 0 then
        vim.notify("No recent project directories are available", vim.log.levels.INFO)
        return
    end

    vim.ui.select(projects, {
        prompt = "Recent Projects",
        format_item = function(path)
            return vim.fn.fnamemodify(path, ":~")
        end,
    }, function(project)
        if not project then
            return
        end

        vim.cmd("lcd " .. vim.fn.fnameescape(project))
        vim.cmd("Telescope find_files")
    end)
end

return M
