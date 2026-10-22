vim.o.background = "dark"

return {
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
                if vim.g.colors_name == "amoled" then
                    local black = "#000000"
                    local muted = "#c0c7d2"
                    local foreground = "#f3f4f6"
                    local blue = "#78a9ff"
                    local border = "#68758a"
                    local orange = "#ffad66"
                    local green = "#70e1a1"
                    local red = "#ff6b7a"
                    local yellow = "#f5d76e"
                    local raised = "#0c1018"
                    local selected = "#1d2430"
                    local bufferline = {
                        BufferLineFill = { bg = black },
                        BufferLineBackground = { fg = muted, bg = raised },
                        BufferLineBuffer = { fg = muted, bg = raised },
                        BufferLineBufferVisible = { fg = foreground, bg = raised },
                        BufferLineBufferSelected = { fg = foreground, bg = selected, bold = true },
                        BufferLineNumbers = { fg = muted, bg = raised },
                        BufferLineNumbersVisible = { fg = foreground, bg = raised },
                        BufferLineNumbersSelected = { fg = blue, bg = selected, bold = true },
                        BufferLineIcon = { fg = muted, bg = raised },
                        BufferLineIconVisible = { fg = foreground, bg = raised },
                        BufferLineIconSelected = { fg = foreground, bg = selected },
                        BufferLineDevIconDefault = { fg = muted, bg = raised },
                        BufferLineDevIconDefaultInactive = { fg = muted, bg = raised },
                        BufferLineDevIconDefaultSelected = { fg = foreground, bg = selected },
                        BufferLineIndicatorSelected = { fg = blue, bg = selected },
                        BufferLineTab = { fg = muted, bg = raised },
                        BufferLineTabSelected = { fg = foreground, bg = selected, bold = true },
                        BufferLineTabClose = { fg = red, bg = raised },
                        BufferLineSeparator = { fg = border, bg = raised },
                        BufferLineSeparatorVisible = { fg = border, bg = raised },
                        BufferLineSeparatorSelected = { fg = border, bg = selected },
                        BufferLineOffsetSeparator = { fg = border, bg = black },
                        BufferLineTruncMarker = { fg = border, bg = black },
                        BufferLineCloseButton = { fg = muted, bg = raised },
                        BufferLineCloseButtonVisible = { fg = muted, bg = raised },
                        BufferLineCloseButtonSelected = { fg = red, bg = selected },
                        BufferLineModified = { fg = orange, bg = raised },
                        BufferLineModifiedVisible = { fg = orange, bg = raised },
                        BufferLineModifiedSelected = { fg = green, bg = selected },
                        BufferLineDiagnostic = { fg = muted, bg = raised },
                        BufferLineDiagnosticVisible = { fg = foreground, bg = raised },
                        BufferLineDiagnosticSelected = { fg = yellow, bg = selected, bold = true },
                        BufferLineError = { fg = red, bg = raised },
                        BufferLineErrorVisible = { fg = red, bg = raised },
                        BufferLineErrorSelected = { fg = red, bg = selected, bold = true },
                        BufferLineWarning = { fg = yellow, bg = raised },
                        BufferLineWarningVisible = { fg = yellow, bg = raised },
                        BufferLineWarningSelected = { fg = yellow, bg = selected, bold = true },
                        BufferLineInfo = { fg = blue, bg = raised },
                        BufferLineInfoVisible = { fg = blue, bg = raised },
                        BufferLineInfoSelected = { fg = blue, bg = selected, bold = true },
                        BufferLineHint = { fg = green, bg = raised },
                        BufferLineHintVisible = { fg = green, bg = raised },
                        BufferLineHintSelected = { fg = green, bg = selected, bold = true },
                        BufferLinePick = { fg = yellow, bg = raised, bold = true },
                        BufferLinePickSelected = { fg = red, bg = selected, bold = true },
                        BufferLineDuplicate = { fg = muted, bg = raised, italic = true },
                        BufferLineDuplicateVisible = { fg = foreground, bg = raised, italic = true },
                        BufferLineDuplicateSelected = { fg = foreground, bg = selected, bold = true, italic = true },
                    }
                    for group, highlight in pairs(bufferline) do
                        vim.api.nvim_set_hl(0, group, highlight)
                    end
                    local groups = vim.fn.getcompletion("BufferLine", "highlight")
                    for _, group in ipairs(groups) do
                        if group:match("DevIcon") or group:match("Icon") or group:match("Numbers") then
                            local is_selected = group:match("Selected$") ~= nil
                            local is_inactive = group:match("Inactive$") ~= nil or group:match("Visible$") ~= nil
                            local bg = is_selected and selected or raised
                            local fg = is_selected and foreground or (is_inactive and foreground or muted)
                            vim.api.nvim_set_hl(0, group, { fg = fg, bg = bg })
                        end
                    end
                    -- Lualine components have their own highlight groups; keep
                    -- progress and location on the same surface as the statusline.
                    for _, group in ipairs({
                        "lualine_b_normal", "lualine_b_insert", "lualine_b_visual", "lualine_b_replace", "lualine_b_command", "lualine_b_inactive",
                        "lualine_y_progress_normal", "lualine_y_progress_insert", "lualine_y_progress_visual", "lualine_y_progress_replace", "lualine_y_progress_command", "lualine_y_progress_inactive",
                        "lualine_b_progress_normal", "lualine_b_progress_insert", "lualine_b_progress_visual", "lualine_b_progress_replace", "lualine_b_progress_command", "lualine_b_progress_inactive",
                        "lualine_y_normal", "lualine_y_insert", "lualine_y_visual", "lualine_y_replace", "lualine_y_command", "lualine_y_inactive",
                        "lualine_z_normal", "lualine_z_insert", "lualine_z_visual", "lualine_z_replace", "lualine_z_command", "lualine_z_inactive",
                    }) do
                        vim.api.nvim_set_hl(0, group, { fg = muted, bg = black })
                    end
                    -- The progress component can reuse its section highlight
                    -- (lualine_b_normal in this setup), so normalize the section
                    -- groups after Lualine has regenerated its mode palette.
                    for _, section in ipairs({ "a", "b", "c", "x", "y", "z" }) do
                        for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
                            local name = "lualine_" .. section .. "_" .. mode
                            local current = vim.api.nvim_get_hl(0, { name = name, link = false })
                            local fg = muted
                            local bg = black
                            if section == "a" then
                                fg = black
                                bg = ({ normal = blue, insert = green, visual = "#c49bff", replace = red, command = orange, inactive = raised })[mode]
                            end
                            vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", current, { fg = fg, bg = bg }))
                        end
                    end
                else
                    for group, target in pairs(links) do
                        vim.api.nvim_set_hl(0, group, { link = target })
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
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                pattern = "*",
                callback = function()
                    if vim.g.colors_name == "amoled" then
                        vim.schedule(apply_theme_links)
                    end
                end,
                desc = "Reapply AMOLED plugin highlights after buffer UI setup",
            })

            local themes = {
                { name = "Catppuccin Latte", colorscheme = "catppuccin-latte", flavour = "latte" },
                { name = "Catppuccin Frappé", colorscheme = "catppuccin-frappe", flavour = "frappe" },
                { name = "Catppuccin Macchiato", colorscheme = "catppuccin-macchiato", flavour = "macchiato" },
                { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha", flavour = "mocha" },
                { name = "AMOLED Black", colorscheme = "amoled" },
            }
            for _, theme in ipairs(themes) do
                theme.key = theme.colorscheme
            end

            local theme_state = vim.fn.stdpath("state") .. "/colorscheme"
            local function save_theme(colorscheme)
                vim.fn.mkdir(vim.fn.stdpath("state"), "p")
                vim.fn.writefile({ colorscheme }, theme_state)
            end
            local function load_theme()
                local saved = vim.fn.readfile(theme_state, "", 1)[1]
                for _, theme in ipairs(themes) do
                    if theme.key == saved then
                        return theme.key
                    end
                end
                return "catppuccin-mocha"
            end

            local function apply_theme(choice)
                vim.o.background = "dark"
                if choice.flavour then
                    require("catppuccin").setup(vim.tbl_deep_extend("force", opts, {
                        flavour = choice.flavour,
                    }))
                end
                local ok, err = pcall(vim.cmd.colorscheme, choice.colorscheme)
                if not ok then
                    return false, err
                end
                apply_theme_links()
                save_theme(choice.key)
                pcall(function() require("lualine").refresh() end)
                return true
            end

            vim.api.nvim_create_user_command("Theme", function()
                vim.ui.select(themes, {
                    prompt = "Choose colorscheme",
                    format_item = function(item) return item.name end,
                }, function(choice)
                    if choice then
                        local ok, err = apply_theme(choice)
                        if not ok then
                            vim.notify("Could not load " .. choice.name .. ": " .. tostring(err), vim.log.levels.ERROR)
                        end
                    end
                end)
            end, { desc = "Choose a coordinated colorscheme" })
            vim.keymap.set("n", "<leader>uC", "<Cmd>Theme<CR>", {
                desc = "Interface: Choose colorscheme",
            })

            local initial_theme = load_theme()
            local selected
            for _, theme in ipairs(themes) do
                if theme.key == initial_theme then selected = theme break end
            end
            selected = selected or themes[4]
            local ok, err = apply_theme(selected)
            if not ok then
                vim.notify("Could not restore colorscheme " .. initial_theme .. ": " .. tostring(err), vim.log.levels.WARN)
                apply_theme(themes[4])
            end
        end,
    },
}
