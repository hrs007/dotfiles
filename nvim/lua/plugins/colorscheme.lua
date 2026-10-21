vim.o.background = "dark"

return {
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = { style = "storm", styles = { sidebars = "dark", floats = "dark" } },
    },
    {
        "ellisonleao/gruvbox.nvim",
        lazy = true,
        opts = { contrast = "medium", transparent_mode = false },
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = true,
        opts = { theme = "wave", background = { dark = "wave", light = "lotus" } },
    },
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = true,
        opts = { variant = "moon", dark_variant = "moon" },
    },
    {
        "EdenEast/nightfox.nvim",
        lazy = true,
        opts = { options = { transparent = false } },
    },
    {
        "gbprod/nord.nvim",
        lazy = true,
        opts = { transparent = false, terminal_colors = true },
    },
    {
        "neanias/everforest-nvim",
        lazy = true,
        config = function()
            require("everforest").setup({
                background = "medium",
                float_style = "bright",
                transparent_background_level = 0,
            })
        end,
    },
    {
        "Mofiqul/dracula.nvim",
        lazy = true,
        opts = {},
    },
    {
        "catppuccin/nvim",

        name = "catppuccin",

        priority = 1000,

        lazy = false,

        opts = {
            flavour = "mocha",

            transparent_background = false,

            term_colors = true,

            styles = {
                comments = { "italic" },
                conditionals = { "italic" },
                loops = {},
                functions = {},
                keywords = { "italic" },
                strings = {},
                variables = {},
            },

            integrations = {
                treesitter = true,
                native_lsp = {
                    enabled = true,
                    underlines = {
                        errors = { "underline" },
                        hints = { "underline" },
                        warnings = { "underline" },
                        information = { "underline" },
                    },
                },
                lualine = true,
                gitsigns = true,
                which_key = true,
                nvimtree = false,
                telescope = {
                    enabled = true,
                },
                cmp = true,
                blink_cmp = true,
            },
        },

        config = function(_, opts)
            -- Keep every picker choice in the dark palette family.
            vim.o.background = "dark"
            require("catppuccin").setup(opts)

            -- Link config-specific highlights to semantic groups so every
            -- colorscheme supplies its own coordinated palette.
            local function apply_theme_links()
                local links = {
                    WinSeparator = "FloatBorder",
                    DiagnosticUnnecessary = "Comment",
                    ConfigUnusedSymbol = "Comment",
                    ConfigReferenceCount = "LineNr",
                    WhichKey = "NormalFloat",
                    WhichKeyNormal = "NormalFloat",
                    WhichKeyBorder = "FloatBorder",
                    WhichKeyTitle = "FloatTitle",
                    WhichKeyGroup = "Keyword",
                    WhichKeyDesc = "Identifier",
                    WhichKeySeparator = "Comment",
                    WhichKeyValue = "Comment",
                    WhichKeyIconAzure = "DiagnosticInfo",
                    WhichKeyIconBlue = "DiagnosticInfo",
                    WhichKeyIconCyan = "DiagnosticHint",
                    WhichKeyIconGreen = "DiagnosticOk",
                    WhichKeyIconGrey = "Comment",
                    WhichKeyIconOrange = "DiagnosticWarn",
                    WhichKeyIconPurple = "Constant",
                    WhichKeyIconRed = "DiagnosticError",
                    WhichKeyIconYellow = "DiagnosticWarn",
                    BufferLineFill = "TabLineFill",
                    BufferLineBackground = "TabLine",
                    BufferLineBufferVisible = "TabLine",
                    BufferLineBufferSelected = "TabLineSel",
                    BufferLineTab = "TabLine",
                    BufferLineTabSelected = "TabLineSel",
                    BufferLineSeparator = "WinSeparator",
                    BufferLineSeparatorVisible = "WinSeparator",
                    BufferLineSeparatorSelected = "WinSeparator",
                    BufferLineCloseButton = "Comment",
                    BufferLineCloseButtonVisible = "Comment",
                    BufferLineCloseButtonSelected = "DiagnosticError",
                    BufferLineModified = "DiagnosticWarn",
                    BufferLineModifiedVisible = "DiagnosticWarn",
                    BufferLineModifiedSelected = "DiagnosticWarn",
                    TelescopeBorder = "FloatBorder",
                    TelescopeTitle = "FloatTitle",
                    TelescopePromptTitle = "FloatTitle",
                    TelescopeResultsTitle = "FloatTitle",
                    TelescopePreviewTitle = "FloatTitle",
                    TelescopeWindowBorder = "FloatBorder",
                    TelescopePromptBorder = "FloatBorder",
                    TelescopeResultsBorder = "FloatBorder",
                    TelescopePreviewBorder = "FloatBorder",
                    TelescopeWindow = "NormalFloat",
                    TelescopeNormal = "NormalFloat",
                    TelescopePromptNormal = "NormalFloat",
                    TelescopeResultsNormal = "NormalFloat",
                    TelescopePreviewNormal = "NormalFloat",
                    TelescopeSelection = "CursorLine",
                    TelescopeSelectionCaret = "CursorLineNr",
                    TelescopeMatching = "Special",
                    TelescopePromptPrefix = "Special",
                    NoiceCmdline = "MsgArea",
                    NoiceCmdlinePopup = "NormalFloat",
                    NoiceCmdlinePopupBorder = "FloatBorder",
                    NoiceConfirm = "NormalFloat",
                    NoiceConfirmBorder = "FloatBorder",
                    NoicePopup = "NormalFloat",
                    NoicePopupBorder = "FloatBorder",
                    NoicePopupmenu = "Pmenu",
                    NoicePopupmenuBorder = "FloatBorder",
                    NoicePopupmenuSelected = "PmenuSel",
                    NoiceSplit = "NormalFloat",
                    NoiceSplitBorder = "FloatBorder",
                    NoiceCmdlineIcon = "Special",
                    NoiceCmdlinePrompt = "Identifier",
                    NoiceCmdlinePopupTitle = "FloatTitle",
                    NoicePopupmenuMatch = "Special",
                    NoiceVirtualText = "Comment",
                    NotifyBackground = "NormalFloat",
                    NotifyERRORBorder = "FloatBorder",
                    NotifyWARNBorder = "FloatBorder",
                    NotifyINFOBorder = "FloatBorder",
                    NotifyDEBUGBorder = "FloatBorder",
                    NotifyTRACEBorder = "FloatBorder",
                    NotifyERRORIcon = "DiagnosticError",
                    NotifyWARNIcon = "DiagnosticWarn",
                    NotifyINFOIcon = "DiagnosticInfo",
                    NotifyDEBUGIcon = "Comment",
                    NotifyTRACEIcon = "DiagnosticHint",
                    NotifyERRORTitle = "DiagnosticError",
                    NotifyWARNTitle = "DiagnosticWarn",
                    NotifyINFOTitle = "DiagnosticInfo",
                    NotifyDEBUGTitle = "Comment",
                    NotifyTRACETitle = "DiagnosticHint",
                    NotifyERRORBody = "NormalFloat",
                    NotifyWARNBody = "NormalFloat",
                    NotifyINFOBody = "NormalFloat",
                    NotifyDEBUGBody = "NormalFloat",
                    NotifyTRACEBody = "NormalFloat",
                    CmpItemAbbr = "Normal",
                    CmpItemAbbrMatch = "Special",
                    CmpItemAbbrMatchFuzzy = "Special",
                    CmpItemMenu = "Comment",
                    CmpItemKind = "Type",
                    CmpItemKindFunction = "Function",
                    CmpItemKindMethod = "Function",
                    CmpItemKindVariable = "Identifier",
                    CmpItemKindClass = "Type",
                    CmpItemKindInterface = "Type",
                    CmpItemKindKeyword = "Keyword",
                    CmpItemKindText = "String",
                    BlinkCmpMenu = "Pmenu",
                    BlinkCmpMenuBorder = "FloatBorder",
                    BlinkCmpLabel = "Normal",
                    BlinkCmpLabelMatch = "Special",
                    BlinkCmpLabelDescription = "Comment",
                    BlinkCmpKind = "Type",
                    BlinkCmpDoc = "NormalFloat",
                    BlinkCmpDocBorder = "FloatBorder",
                    BlinkCmpSignatureHelp = "NormalFloat",
                    BlinkCmpSignatureHelpBorder = "FloatBorder",
                    TroubleNormal = "NormalFloat",
                    TroubleNormalNC = "NormalFloat",
                    TroubleText = "Normal",
                    TroublePreview = "Visual",
                    TroubleFilename = "Directory",
                    TroubleDirectory = "Directory",
                    TroubleIconDirectory = "Special",
                    TroubleSource = "Comment",
                    TroubleCode = "Special",
                    TroublePos = "LineNr",
                    TroubleCount = "TabLineSel",
                    TroubleIndent = "LineNr",
                    TroubleIndentFoldClosed = "CursorLineNr",
                    TroubleIndentFoldOpen = "LineNr",
                    TroubleIndentTop = "LineNr",
                    TroubleIndentMiddle = "LineNr",
                    TroubleIndentLast = "LineNr",
                    TroubleIndentWs = "LineNr",
                    TroubleIconArray = "Delimiter",
                    TroubleIconBoolean = "Boolean",
                    TroubleIconClass = "Type",
                    TroubleIconConstant = "Constant",
                    TroubleIconConstructor = "Type",
                    TroubleIconEnum = "Type",
                    TroubleIconEnumMember = "Constant",
                    TroubleIconEvent = "Special",
                    TroubleIconField = "Identifier",
                    TroubleIconFile = "Normal",
                    TroubleIconFunction = "Function",
                    TroubleIconInterface = "Type",
                    TroubleIconKey = "Keyword",
                    TroubleIconMethod = "Function",
                    TroubleIconModule = "Include",
                    TroubleIconNamespace = "Include",
                    TroubleIconNull = "Constant",
                    TroubleIconNumber = "Number",
                    TroubleIconObject = "Constant",
                    TroubleIconOperator = "Operator",
                    TroubleIconPackage = "Include",
                    TroubleIconProperty = "Identifier",
                    TroubleIconString = "String",
                    TroubleIconStruct = "Type",
                    TroubleIconTypeParameter = "Type",
                    TroubleIconVariable = "Identifier",
                    OilDir = "Directory",
                    OilDirIcon = "Directory",
                    OilFile = "Normal",
                    OilLink = "Special",
                    OilLinkTarget = "Comment",
                    OilSocket = "Special",
                    OilCopy = "DiagnosticInfo",
                    OilMove = "DiagnosticWarn",
                    OilCreate = "DiagnosticOk",
                    OilDelete = "DiagnosticError",
                    OilTrash = "DiagnosticError",
                    OilChange = "DiagnosticWarn",
                    OilPermission = "Comment",
                    OilSize = "Comment",
                    OilMtime = "Comment",
                    OilType = "Comment",
                    OilPreviewFloat = "NormalFloat",
                    FugitiveHeader = "Title",
                    FugitiveHeading = "Title",
                    FugitiveHelpHeader = "Title",
                    FugitiveUnstagedSection = "DiagnosticWarn",
                    FugitiveStagedSection = "DiagnosticOk",
                    FugitiveUntrackedSection = "DiagnosticInfo",
                    FugitiveRenamedSection = "DiagnosticHint",
                    FugitiveHunk = "Comment",
                    FugitiveHash = "Comment",
                    FugitivePath = "Directory",
                    FugitiveSymbolicRef = "Special",
                    diffAdded = "DiffAdd",
                    diffRemoved = "DiffDelete",
                    diffChanged = "DiffChange",
                    diffOldFile = "Removed",
                    diffNewFile = "Added",
                    ["@lsp.typemod.variable.unused"] = "Comment",
                    ["@lsp.typemod.parameter.unused"] = "Comment",
                    ["@lsp.typemod.function.unused"] = "Comment",
                    ["@lsp.typemod.property.unused"] = "Comment",
                    ["@lsp.typemod.field.unused"] = "Comment",
                    ["@lsp.typemod.type.unused"] = "Comment",
                    ["@lsp.typemod.class.unused"] = "Comment",
                }
                for group, target in pairs(links) do
                    vim.api.nvim_set_hl(0, group, { link = target })
                end

                if vim.g.colors_name == "amoled" then
                    local black = "#000000"
                    local muted = "#b8b8b8"
                    local foreground = "#ffffff"
                    local blue = "#9bbcff"
                    local border = "#808080"
                    local orange = "#ffc078"
                    local green = "#a8f0b5"
                    local red = "#ff8fa3"
                    local yellow = "#ffe08a"
                    local bufferline = {
                        BufferLineFill = { bg = black },
                        BufferLineBackground = { fg = muted, bg = black },
                        BufferLineBuffer = { fg = muted, bg = black },
                        BufferLineBufferVisible = { fg = "#d0d0d0", bg = black },
                        BufferLineBufferSelected = { fg = foreground, bg = black, bold = true },
                        BufferLineIndicatorSelected = { fg = blue, bg = black, underline = true, sp = blue },
                        BufferLineTab = { fg = muted, bg = black },
                        BufferLineTabSelected = { fg = foreground, bg = black, bold = true, underline = true, sp = blue },
                        BufferLineTabClose = { fg = red, bg = black },
                        BufferLineSeparator = { fg = border, bg = black },
                        BufferLineSeparatorVisible = { fg = border, bg = black },
                        BufferLineSeparatorSelected = { fg = border, bg = black },
                        BufferLineOffsetSeparator = { fg = border, bg = black },
                        BufferLineTruncMarker = { fg = border, bg = black },
                        BufferLineCloseButton = { fg = muted, bg = black },
                        BufferLineCloseButtonVisible = { fg = muted, bg = black },
                        BufferLineCloseButtonSelected = { fg = red, bg = black },
                        BufferLineModified = { fg = orange, bg = black },
                        BufferLineModifiedVisible = { fg = orange, bg = black },
                        BufferLineModifiedSelected = { fg = green, bg = black },
                        BufferLineDiagnostic = { fg = muted, bg = black },
                        BufferLineDiagnosticVisible = { fg = "#d0d0d0", bg = black },
                        BufferLineDiagnosticSelected = { fg = yellow, bg = black, bold = true },
                        BufferLineError = { fg = red, bg = black },
                        BufferLineErrorVisible = { fg = red, bg = black },
                        BufferLineErrorSelected = { fg = red, bg = black, bold = true },
                        BufferLineWarning = { fg = yellow, bg = black },
                        BufferLineWarningVisible = { fg = yellow, bg = black },
                        BufferLineWarningSelected = { fg = yellow, bg = black, bold = true },
                        BufferLineInfo = { fg = blue, bg = black },
                        BufferLineInfoVisible = { fg = blue, bg = black },
                        BufferLineInfoSelected = { fg = blue, bg = black, bold = true },
                        BufferLineHint = { fg = green, bg = black },
                        BufferLineHintVisible = { fg = green, bg = black },
                        BufferLineHintSelected = { fg = green, bg = black, bold = true },
                        BufferLinePick = { fg = yellow, bg = black, bold = true },
                        BufferLinePickSelected = { fg = red, bg = black, bold = true },
                        BufferLineDuplicate = { fg = muted, bg = black, italic = true },
                        BufferLineDuplicateVisible = { fg = "#d0d0d0", bg = black, italic = true },
                        BufferLineDuplicateSelected = { fg = foreground, bg = black, bold = true, italic = true },
                    }
                    for group, highlight in pairs(bufferline) do
                        vim.api.nvim_set_hl(0, group, highlight)
                    end
                end
            end

            local group = vim.api.nvim_create_augroup("config.colorscheme_ui", { clear = true })
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = group,
                callback = function()
                    -- Run after the colorscheme's own autocmds so plugin
                    -- highlights cannot leave stale colors behind.
                    vim.schedule(apply_theme_links)
                end,
                desc = "Keep custom UI highlights aligned with the selected theme",
            })
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "VeryLazy",
                callback = apply_theme_links,
                desc = "Reapply theme links after lazy plugins finish setup",
            })

            local themes = {
                { name = "Catppuccin Mocha", colorscheme = "catppuccin" },
                { name = "Catppuccin Macchiato", colorscheme = "catppuccin-macchiato" },
                { name = "Catppuccin Frappe", colorscheme = "catppuccin-frappe" },
                { name = "Tokyo Night", colorscheme = "tokyonight-night" },
                { name = "Tokyo Night Storm", colorscheme = "tokyonight-storm" },
                { name = "Tokyo Night Moon", colorscheme = "tokyonight-moon" },
                { name = "Gruvbox", colorscheme = "gruvbox" },
                { name = "Kanagawa Wave", colorscheme = "kanagawa-wave" },
                { name = "Kanagawa Dragon", colorscheme = "kanagawa-dragon" },
                { name = "Rosé Pine Moon", colorscheme = "rose-pine-moon" },
                { name = "Nightfox", colorscheme = "nightfox" },
                { name = "Duskfox", colorscheme = "duskfox" },
                { name = "Nordfox", colorscheme = "nordfox" },
                { name = "Terafox", colorscheme = "terafox" },
                { name = "Carbonfox", colorscheme = "carbonfox" },
                { name = "Nord", colorscheme = "nord" },
                { name = "Everforest Dark", colorscheme = "everforest" },
                { name = "Dracula", colorscheme = "dracula" },
                { name = "Dracula Soft", colorscheme = "dracula-soft" },
                { name = "AMOLED Black", colorscheme = "amoled" },
            }

            local theme_state = vim.fn.stdpath("state") .. "/colorscheme"
            local function save_theme(colorscheme)
                vim.fn.mkdir(vim.fn.stdpath("state"), "p")
                vim.fn.writefile({ colorscheme }, theme_state)
            end
            local function load_theme()
                local saved = vim.fn.readfile(theme_state, "", 1)[1]
                for _, theme in ipairs(themes) do
                    if theme.colorscheme == saved then
                        return saved
                    end
                end
                return "catppuccin"
            end

            vim.api.nvim_create_user_command("Theme", function()
                vim.ui.select(themes, {
                    prompt = "Choose colorscheme",
                    format_item = function(item) return item.name end,
                }, function(choice)
                    if choice then
                        vim.o.background = "dark"
                        local ok, err = pcall(vim.cmd.colorscheme, choice.colorscheme)
                        if not ok then
                            vim.notify("Could not load " .. choice.name .. ": " .. tostring(err), vim.log.levels.ERROR)
                            return
                        end
                        apply_theme_links()
                        save_theme(choice.colorscheme)
                        pcall(function() require("lualine").refresh() end)
                    end
                end)
            end, { desc = "Choose a coordinated colorscheme" })
            vim.keymap.set("n", "<leader>uC", "<Cmd>Theme<CR>", {
                desc = "Interface: Choose colorscheme",
            })

            local initial_theme = load_theme()
            local ok, err = pcall(vim.cmd.colorscheme, initial_theme)
            if not ok then
                vim.notify("Could not restore colorscheme " .. initial_theme .. ": " .. tostring(err), vim.log.levels.WARN)
                vim.cmd.colorscheme("catppuccin")
            end
            apply_theme_links()
        end,
    },
}
