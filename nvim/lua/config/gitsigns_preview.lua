local M = {}

function M.setup()
    local preview = require("gitsigns.hunk_preview")
    local api = vim.api

    preview.highlight_added_hunk = function(bufnr, namespace, hunk)
        local start_row = hunk.added.start - 1

        for offset = 0, hunk.added.count - 1 do
            local row = start_row + offset
            api.nvim_buf_set_extmark(bufnr, namespace, row, 0, {
                end_row = row + 1,
                hl_group = "GitSignsAddPreview",
                hl_eol = true,
                priority = 1000,
            })
        end

        local _, added_regions = require("gitsigns.diff_int").run_word_diff(
            hunk.removed.lines,
            hunk.added.lines
        )

        for _, region in ipairs(added_regions) do
            local offset, kind = region[1] - 1, region[2]
            local start_col, end_col = region[3] - 1, region[4] - 1
            local row = start_row + offset
            local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]

            if line then
                -- Diff offsets can point past EOL or into a UTF-8 character.
                start_col = math.min(math.max(start_col, 0), #line)
                end_col = math.min(math.max(end_col, start_col), #line)
                start_col = vim.str_byteindex(
                    line,
                    "utf-32",
                    vim.str_utfindex(line, "utf-32", start_col, false),
                    false
                )
                end_col = vim.str_byteindex(
                    line,
                    "utf-32",
                    vim.str_utfindex(line, "utf-32", end_col, false),
                    false
                )

                local cr_at_eol_change = kind == "change" and vim.endswith(line, "\r")
                if end_col > start_col then
                    pcall(api.nvim_buf_set_extmark, bufnr, namespace, row, start_col, {
                        end_col = end_col,
                        strict = not cr_at_eol_change,
                        hl_group = kind == "add" and "GitSignsAddInline"
                            or kind == "change" and "GitSignsChangeInline"
                            or "GitSignsDeleteInline",
                        priority = 1001,
                    })
                end
            end
        end
    end
end

return M
