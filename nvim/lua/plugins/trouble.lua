local saved_panel_sizes = {}

local function is_vertical_panel(view)
    return view.win.opts.position == "left" or view.win.opts.position == "right"
end

local function redraw_panel(view)
    vim.schedule(function()
        if view:is_open() then
            view:render()
            vim.cmd("redraw!")
        end
    end)
end

local function resize_panel(view, delta)
    local win = view.win.win
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local vertical = is_vertical_panel(view)
    local amount = vertical and 8 or 3
    local size = vertical and vim.api.nvim_win_get_width(win) or vim.api.nvim_win_get_height(win)
    local new_size = math.max(vertical and 24 or 5, size + (delta > 0 and amount or -amount))
    if vertical then
        vim.api.nvim_win_set_width(win, new_size)
    else
        vim.api.nvim_win_set_height(win, new_size)
    end
    view.win.opts.size = new_size
    redraw_panel(view)
end

local function toggle_panel_size(view)
    local win = view.win.win
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local saved = saved_panel_sizes[win]
    if saved then
        if saved.vertical then
            vim.api.nvim_win_set_width(win, saved.size)
        else
            vim.api.nvim_win_set_height(win, saved.size)
        end
        view.win.opts.size = saved.size
        saved_panel_sizes[win] = nil
        redraw_panel(view)
        return
    end

    local vertical = is_vertical_panel(view)
    local current_size = vertical and vim.api.nvim_win_get_width(win) or vim.api.nvim_win_get_height(win)
    saved_panel_sizes[win] = { size = current_size, vertical = vertical }
    if vertical then
        local max_width = math.max(24, vim.o.columns - 30)
        local target_width = math.min(max_width, math.max(current_size + 16, math.floor(vim.o.columns * 0.5)))
        vim.api.nvim_win_set_width(win, target_width)
        view.win.opts.size = target_width
    else
        local target_height = math.min(vim.o.lines - 6, math.max(8, math.floor(vim.o.lines * 0.55)))
        vim.api.nvim_win_set_height(win, target_height)
        view.win.opts.size = target_height
    end
    redraw_panel(view)
end

vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(event)
        saved_panel_sizes[tonumber(event.match)] = nil
    end,
})

return {
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {
            -- Move focus into the Trouble list whenever it opens.
            focus = true,
            -- Keep list views visible even before quickfix or location lists
            -- have any entries, so these shortcuts still give clear feedback.
            open_no_results = true,
            win = {
                position = "bottom",
                size = 10,
                border = "rounded",
            },
            keys = {
                ["+"] = { action = function(view) resize_panel(view, 1) end, desc = "Increase panel size" },
                ["-"] = { action = function(view) resize_panel(view, -1) end, desc = "Decrease panel size" },
                ["="] = { action = toggle_panel_size, desc = "Maximize / restore panel" },
            },
            modes = {
                project_diagnostics = {
                    mode = "diagnostics",
                    desc = "Project diagnostics",
                    -- Keep the workspace list scoped to the project containing
                    -- the current file and group entries by filename.
                    filter = function(items)
                        local file = vim.api.nvim_buf_get_name(0)
                        local root
                        if file ~= "" and not file:match("^term://") and not file:match("^oil://") then
                            root = vim.fs.root(file, {
                                ".git",
                                "pyproject.toml",
                                "ruff.toml",
                                ".ruff.toml",
                                "package.json",
                                "CMakeLists.txt",
                                "Makefile",
                            })
                        end
                        root = vim.fs.normalize(root or vim.fn.getcwd())
                        local separator = package.config:sub(1, 1)
                        local root_prefix = root:sub(-1) == separator and root or (root .. separator)
                        local root_lower = root:lower()

                        return vim.tbl_filter(function(item)
                            local filename = item.filename
                            if not filename then
                                return false
                            end
                            filename = vim.fs.normalize(filename)
                            local path = filename:lower()
                            return path == root_lower or path:sub(1, #root_prefix) == root_prefix:lower()
                        end, items)
                    end,
                    groups = {
                        { "filename", format = "{file_icon} {basename:Title} {count}" },
                    },
                },
            },
        },
        keys = {
            {
                "<leader>xx",
                "<Cmd>Trouble project_diagnostics toggle auto_preview=false<CR>",
                desc = "Diagnostics: Workspace",
            },
            {
                "<leader>xd",
                "<Cmd>Trouble diagnostics toggle filter.buf=0 auto_preview=false<CR>",
                desc = "Diagnostics: Current file",
            },
            {
                "<leader>xq",
                "<Cmd>Trouble qflist toggle auto_preview=false<CR>",
                desc = "Quickfix list",
            },
            {
                "<leader>xQ",
                function()
                    vim.diagnostic.setqflist({ open = false, title = "Workspace diagnostics" })
                    vim.cmd("Trouble qflist focus=true auto_preview=false")
                end,
                desc = "Quickfix: Workspace diagnostics",
            },
            {
                "<leader>xl",
                "<Cmd>Trouble loclist toggle auto_preview=false<CR>",
                desc = "Location list",
            },
            {
                "<leader>xL",
                function()
                    vim.diagnostic.setloclist({ open = false, title = "File diagnostics" })
                    vim.cmd("Trouble loclist focus=true auto_preview=false")
                end,
                desc = "Location list: File diagnostics",
            },
            {
                "<leader>cn",
                "<Cmd>Trouble lsp toggle focus=true auto_preview=false<CR>",
                desc = "Code: Definitions, implementations, references",
            },
            {
                "<leader>co",
                -- Keep symbol navigation in the outline. Trouble's default
                -- preview follows every selection and can resize/repaint the
                -- editor split while the side panel is active.
                "<Cmd>Trouble symbols toggle pinned=true focus=true auto_preview=false win.position=right win.size=44<CR>",
                desc = "Code: Outline",
            },
        },
    },
}
