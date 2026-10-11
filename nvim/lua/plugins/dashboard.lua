return {
    {
        "nvimdev/dashboard-nvim",
        event = "VimEnter",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("dashboard").setup({
                theme = "hyper",
                change_to_vcs_root = true,

                config = {
                    header = {
                        "",
                        "  ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
                        "  ████╗  ██║██║   ██║██║████╗ ████║",
                        "  ██╔██╗ ██║██║   ██║██║██╔████╔██║",
                        "  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                        "  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
                        "  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
                        "",
                    },

                    shortcut = {
                        {
                            desc = "Find File",
                            group = "Label",
                            action = "Telescope find_files",
                            key = "f",
                        },
                        {
                            desc = "Find Text",
                            group = "Label",
                            action = "Telescope live_grep",
                            key = "g",
                        },
                        {
                            desc = "Recent Files",
                            group = "Label",
                            action = "Telescope oldfiles",
                            key = "r",
                        },
                        {
                            desc = "New File",
                            group = "Label",
                            action = "enew",
                            key = "n",
                        },
                        {
                            desc = "Plugin Manager",
                            group = "Label",
                            action = "Lazy",
                            key = "l",
                        },
                        {
                            desc = "Quit Neovim",
                            group = "Label",
                            action = "qa",
                            key = "q",
                        },
                    },

                    project = {
                        enable = true,
                        limit = 5,
                        label = " Recent Projects",
                        action = "Telescope find_files cwd=",
                    },

                    mru = {
                        enable = true,
                        limit = 8,
                        label = " Recent Files",
                        cwd_only = false,
                    },

                    footer = {
                        "",
                        "Happy coding!",
                    },
                },
            })
        end,
    },
}
