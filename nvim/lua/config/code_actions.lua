-- Route selection prompts through a numbered Telescope picker. Its visible
-- prompt keeps typed numbers visible and gives every choice a clear index.
local M = {}
local original_select = vim.ui.select

local function select_numbered(items, opts, on_choice)
    opts = opts or {}
    if type(items) ~= "table" or #items == 0 then
        if on_choice then on_choice(nil, nil) end
        return
    end
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        return original_select(items, opts, on_choice)
    end

    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local entries = {}
    local width = math.max(2, #tostring(#items))
    for index, item in ipairs(items) do
        local label = opts.format_item and opts.format_item(item) or tostring(item)
        if label == nil then label = tostring(item) end
        entries[#entries + 1] = {
            value = item,
            index = index,
            label = (("%" .. width .. "d  %s"):format(index, label)),
        }
    end

    pickers.new({}, {
        prompt_title = (opts.prompt or "Select an option") .. " · type a number or search",
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.label,
                    ordinal = entry.label,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        sorting_strategy = "ascending",
        previewer = false,
        layout_config = { width = 0.68, height = math.min(0.72, math.max(0.28, (#entries + 4) / 20)) },
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selected = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local entry = selected and selected.value
                if on_choice then on_choice(entry and entry.value or nil, entry and entry.index or nil) end
            end)
            return true
        end,
    }):find()
end

function M.setup()
    vim.ui.select = function(items, opts, on_choice)
        return select_numbered(items, opts, on_choice)
    end
end

function M.open()
    vim.lsp.buf.code_action()
end

function M.web_menu()
    local actions = {
        { label = "All available code actions", only = nil },
        { label = "Organize imports", only = { "source.organizeImports" } },
        { label = "Fix all ESLint issues", only = { "source.fixAll.eslint" } },
    }
    vim.ui.select(actions, {
        prompt = "TypeScript / ESLint action",
        format_item = function(action) return action.label end,
    }, function(action)
        if not action then return end
        vim.lsp.buf.code_action({ context = { only = action.only } })
    end)
end

return M
