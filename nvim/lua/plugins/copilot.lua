return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = { "BufReadPost", "BufNewFile" },
        keys = {
            { "<leader>at", "<Cmd>Copilot toggle<CR>", desc = "AI: Toggle Copilot" },
            { "<leader>as", "<Cmd>Copilot status<CR>", desc = "AI: Copilot status" },
        },
        dependencies = {
            "zbirenbaum/copilot-cmp",
        },
        opts = {
            suggestion = { enabled = false },
            panel = { enabled = false },
        },
        config = function(_, opts)
            require("copilot").setup(opts)

            -- copilot-cmp calls Neovim's deprecated client.is_stopped() API.
            -- Use the current method form so the warning does not appear per buffer.
            local source = require("copilot_cmp.source")
            source.is_available = function(self)
                if self.client:is_stopped() or self.client.name ~= "copilot" then
                    return false
                end

                local clients
                if vim.lsp.get_clients then
                    clients = vim.lsp.get_clients({
                        bufnr = vim.api.nvim_get_current_buf(),
                        id = self.client.id,
                    })
                else
                    clients = vim.lsp.get_active_clients({
                        bufnr = vim.api.nvim_get_current_buf(),
                        id = self.client.id,
                    })
                end
                return next(clients) ~= nil
            end

            require("copilot_cmp").setup()
        end,
    },
}
