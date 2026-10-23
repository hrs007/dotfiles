return {
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        keys = {
            { "<leader>gg", "<cmd>Neogit<cr>", desc = "Open Neogit" },
        },
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("neogit").setup({})
        end,
    },
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "G", "Gpull", "Gpush", "Gfetch" },
        build = function(plugin)
            -- Fugitive's async exit callback errors when a command produces
            -- no stdout or stderr. Keep its job result fields nil-safe after
            -- plugin updates until the upstream callback handles empty jobs.
            local path = vim.fs.joinpath(plugin.dir, "autoload", "fugitive.vim")
            local lines = vim.fn.readfile(path)
            local changed = false
            for index, line in ipairs(lines) do
                if line == "  let a:dict.stdout = self.stdout" then
                    lines[index] = "  let a:dict.stdout = get(self, 'stdout', [])"
                    changed = true
                elseif line == "  let a:dict.stderr = self.stderr" then
                    lines[index] = "  let a:dict.stderr = get(self, 'stderr', [])"
                    changed = true
                end
            end
            if changed then
                vim.fn.writefile(lines, path)
            end
        end,
        init = function()
            -- Fugitive command panels can use different filetypes, so also
            -- recognize Fugitive's own buffer-name scheme. This covers Git
            -- status, log, diff, blame, and other command output buffers.
            local function map_fugitive_close(buf)
                if not vim.api.nvim_buf_is_valid(buf) then return end
                local filetype = vim.bo[buf].filetype
                local name = vim.api.nvim_buf_get_name(buf)
                local fugitive_buffer = filetype == "fugitive"
                    or filetype == "fugitiveblame"
                    or filetype == "git"
                    or name:match("^fugitive://") ~= nil
                    or vim.b[buf].fugitive_type ~= nil
                if not fugitive_buffer then return end

                vim.keymap.set("n", "q", "<Cmd>close<CR>", {
                    buffer = buf,
                    silent = true,
                    desc = "Fugitive: Close panel",
                })
            end

            vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
                callback = function(event)
                    local buf = event.buf
                    map_fugitive_close(buf)
                    -- Fugitive may finish setting a panel's filetype and
                    -- mappings later in the same event cycle; reassert q
                    -- after those callbacks so it consistently closes.
                    vim.schedule(function() map_fugitive_close(buf) end)

                    vim.schedule(function()
                        if not vim.api.nvim_buf_is_valid(buf) then return end
                        local filetype = vim.bo[buf].filetype
                        local name = vim.api.nvim_buf_get_name(buf)
                        if filetype ~= "fugitive" and filetype ~= "fugitiveblame"
                            and filetype ~= "git" and not name:match("^fugitive://")
                            and vim.b[buf].fugitive_type == nil then
                            return
                        end
                        vim.keymap.set("n", "<leader>pz", function()
                            require("config.window_zoom").toggle()
                        end, {
                            buffer = buf,
                            silent = true,
                            desc = "Window: Zoom / restore split",
                        })
                    end)
                end,
            })
        end,
        keys = {
            { "<leader>gf", "<cmd>Git<cr>", desc = "Open Fugitive status" },
        },
        config = function()
            -- Fugitive replaced the old :Gpull/:Gpush/:Gfetch commands with
            -- :Git pull/push/fetch. Keep those familiar command names as
            -- lightweight aliases for existing workflows.
            for _, action in ipairs({ "pull", "push", "fetch" }) do
                local git_action = action
                local command = "G" .. git_action
                vim.api.nvim_create_user_command(command, function(opts)
                    local args = { git_action }
                    vim.list_extend(args, opts.fargs)
                    vim.cmd({ cmd = "Git", args = args })
                end, {
                    nargs = "*",
                    desc = "Fugitive: git " .. git_action,
                })
            end
        end,
    },
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        keys = {
            { "<leader>gl", "<cmd>LazyGit<cr>", desc = "Open Lazygit" },
        },
        dependencies = { "nvim-lua/plenary.nvim" },
    },
}
