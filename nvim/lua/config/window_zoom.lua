local M = {}
local zoom_layouts = {}

function M.toggle()
    local api = vim.api
    local tab = api.nvim_get_current_tabpage()
    local current = api.nvim_get_current_win()
    local saved = zoom_layouts[tab]
    if saved then
        if pcall(api.nvim_set_current_win, saved.current) then
            pcall(vim.cmd, "wincmd =")
            for win, size in pairs(saved.sizes) do
                if api.nvim_win_is_valid(win) and api.nvim_win_get_tabpage(win) == tab then
                    pcall(api.nvim_win_set_width, win, size.width)
                    pcall(api.nvim_win_set_height, win, size.height)
                end
            end
        end
        zoom_layouts[tab] = nil
        return
    end

    local sizes = {}
    for _, win in ipairs(api.nvim_tabpage_list_wins(tab)) do
        if api.nvim_win_get_config(win).relative == "" then
            sizes[win] = { width = api.nvim_win_get_width(win), height = api.nvim_win_get_height(win) }
        end
    end
    if vim.tbl_count(sizes) < 2 then
        return
    end

    zoom_layouts[tab] = { current = current, sizes = sizes }
    vim.cmd("wincmd _")
    vim.cmd("wincmd |")
end

return M
