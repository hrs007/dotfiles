return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = { "BufReadPost", "BufNewFile" },
        keys = {
            { "<leader>at", "<Cmd>Copilot toggle<CR>", desc = "AI: Toggle Copilot" },
            { "<leader>as", "<Cmd>Copilot status<CR>", desc = "AI: Copilot status" },
        },
        opts = {
            suggestion = { enabled = false },
            panel = { enabled = false },
        },
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        cmd = { "CopilotChat", "CopilotChatOpen", "CopilotChatToggle" },
        keys = {
            {
                "<leader>ac",
                function()
                    require("CopilotChat").toggle()
                end,
                desc = "AI: Copilot Chat",
            },
        },
        dependencies = {
            { "nvim-lua/plenary.nvim", branch = "master" },
            "zbirenbaum/copilot.lua",
        },
        opts = {
            window = {
                layout = "vertical",
                width = 0.4,
                border = "rounded",
                title = "Copilot Chat",
            },
            auto_insert_mode = true,
        },
    },
}
