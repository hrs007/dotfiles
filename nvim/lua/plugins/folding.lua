return {
    {
        "kevinhwang91/nvim-ufo",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "kevinhwang91/promise-async" },
        opts = {
            open_fold_hl_timeout = 150,
            fold_virt_text_handler = function(virtual_text, line, end_line, width, truncate)
                local summary = ("  ↕ %d lines"):format(end_line - line)
                local target_width = math.max(1, width - vim.fn.strdisplaywidth(summary))
                local result, current_width = {}, 0

                for _, chunk in ipairs(virtual_text) do
                    local chunk_text, highlight = chunk[1], chunk[2]
                    local chunk_width = vim.fn.strdisplaywidth(chunk_text)
                    if current_width + chunk_width <= target_width then
                        result[#result + 1] = chunk
                        current_width = current_width + chunk_width
                    else
                        local shortened = truncate(chunk_text, target_width - current_width)
                        if shortened ~= "" then
                            result[#result + 1] = { shortened, highlight }
                        end
                        break
                    end
                end

                result[#result + 1] = { summary, "MoreMsg" }
                return result
            end,
            preview = {
                win_config = {
                    border = "rounded",
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
                    winblend = 0,
                },
            },
        },
        config = function(_, opts)
            require("ufo").setup(opts)
            vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
            vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
            vim.keymap.set("n", "<leader>zp", require("ufo").peekFoldedLinesUnderCursor, {
                desc = "Preview folded code",
            })
        end,
    },
}
