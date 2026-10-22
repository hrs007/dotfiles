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
                    WhichKeyGroup = "NormalFloat",
                    WhichKeyDesc = "NormalFloat",
                    WhichKeySeparator = "NormalFloat",
                    WhichKeyValue = "NormalFloat",
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
                    BufferLineDiagnosticError = "DiagnosticError",
                    BufferLineDiagnosticErrorVisible = "DiagnosticError",
                    BufferLineDiagnosticErrorSelected = "DiagnosticError",
                    BufferLineDiagnosticWarning = "DiagnosticWarn",
                    BufferLineDiagnosticWarningVisible = "DiagnosticWarn",
                    BufferLineDiagnosticWarningSelected = "DiagnosticWarn",
                    BufferLineDiagnosticInfo = "DiagnosticInfo",
                    BufferLineDiagnosticInfoVisible = "DiagnosticInfo",
                    BufferLineDiagnosticInfoSelected = "DiagnosticInfo",
                    BufferLineDiagnosticHint = "DiagnosticHint",
                    BufferLineDiagnosticHintVisible = "DiagnosticHint",
                    BufferLineDiagnosticHintSelected = "DiagnosticHint",
                    BufferLineDiagnosticError = "Normal",
                    BufferLineDiagnosticErrorVisible = "Normal",
                    BufferLineDiagnosticErrorSelected = "Normal",
                    BufferLineDiagnosticWarning = "Normal",
                    BufferLineDiagnosticWarningVisible = "Normal",
                    BufferLineDiagnosticWarningSelected = "Normal",
                    BufferLineDiagnosticInfo = "Normal",
                    BufferLineDiagnosticInfoVisible = "Normal",
                    BufferLineDiagnosticInfoSelected = "Normal",
                    BufferLineDiagnosticHint = "Normal",
                    BufferLineDiagnosticHintVisible = "Normal",
                    BufferLineDiagnosticHintSelected = "Normal",
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
                if vim.g.colors_name == "amoled" or vim.g.colors_name == "solarized" or vim.g.colors_name == "purelight" then
                    local function color(group, key, fallback)
                        local ok, value = pcall(vim.api.nvim_get_hl, 0, { name = group, link = true })
                        local result = ok and value[key] or nil
                        if type(result) == "number" then
                            return string.format("#%06x", result)
                        end
                        return fallback
                    end
                    local black = color("Normal", "bg", "#000000")
                    local muted = color("TabLine", "fg", color("Normal", "fg", black))
                    local foreground = color("Normal", "fg", muted)
                    local blue = color("DiagnosticInfo", "fg", foreground)
                    local border = color("FloatBorder", "fg", muted)
                    local orange = color("DiagnosticWarn", "fg", foreground)
                    local green = color("DiagnosticOk", "fg", foreground)
                    local red = color("DiagnosticError", "fg", foreground)
                    local yellow = color("DiagnosticWarn", "fg", foreground)
                    local raised = color("NormalFloat", "bg", black)
                    -- Derive the active tab from each scheme's own selection
                    -- palette, preserving the identity of each colorscheme.
                    local selected = color("PmenuSel", "bg", color("CursorLine", "bg", raised))
                    local selected_fg = color("PmenuSel", "fg", foreground)
                    local selected_accent = blue
                    if vim.g.colors_name == "solarized" and vim.o.background == "light" then
                        selected = "#eee8d5" -- Solarized base2 paper
                        selected_fg = "#073642" -- Solarized base02 ink
                        selected_accent = "#268bd2"
                    elseif vim.g.colors_name == "purelight" then
                        selected = "#dce6ef"
                        selected_fg = "#17212b"
                        selected_accent = "#0759a5"
                    elseif vim.g.colors_name == "solarized" then
                        selected = "#073642" -- Solarized base02 raised surface
                        selected_fg = "#eee8d5" -- Solarized base2 text
                        selected_accent = "#2aa198"
                    end
                    local visual = color("Statement", "fg", blue)
                    local comment = color("NormalFloat", "fg", foreground)
                    local type_color = color("Type", "fg", foreground)
                    local bufferline = {
                        BufferLineFill = { bg = black },
                        BufferLineBackground = { fg = foreground, bg = raised },
                        BufferLineBuffer = { fg = foreground, bg = raised },
                        BufferLineBufferVisible = { fg = foreground, bg = raised },
                        BufferLineBufferSelected = { fg = selected_fg, bg = selected, bold = true },
                        BufferLineNumbers = { fg = foreground, bg = raised },
                        BufferLineNumbersVisible = { fg = foreground, bg = raised },
                        BufferLineNumbersSelected = { fg = selected_accent, bg = selected, bold = true },
                        BufferLineIcon = { fg = muted, bg = raised },
                        BufferLineIconVisible = { fg = foreground, bg = raised },
                        BufferLineIconSelected = { fg = foreground, bg = selected },
                        BufferLineDevIconDefault = { fg = muted, bg = raised },
                        BufferLineDevIconDefaultInactive = { fg = muted, bg = raised },
                        BufferLineDevIconDefaultSelected = { fg = foreground, bg = selected },
                        BufferLineIndicatorSelected = { fg = selected_accent, bg = selected },
                        BufferLineTab = { fg = foreground, bg = raised },
                        BufferLineTabSelected = { fg = selected_fg, bg = selected, bold = true },
                        BufferLineTabClose = { fg = red, bg = raised },
                        BufferLineSeparator = { fg = border, bg = raised },
                        BufferLineSeparatorVisible = { fg = border, bg = raised },
                        BufferLineSeparatorSelected = { fg = blue, bg = selected },
                        BufferLineOffsetSeparator = { fg = border, bg = black },
                        BufferLineTruncMarker = { fg = border, bg = black },
                        BufferLineCloseButton = { fg = foreground, bg = raised },
                        BufferLineCloseButtonVisible = { fg = foreground, bg = raised },
                        BufferLineCloseButtonSelected = { fg = red, bg = selected },
                        BufferLineModified = { fg = orange, bg = raised },
                        BufferLineModifiedVisible = { fg = orange, bg = raised },
                        BufferLineModifiedSelected = { fg = green, bg = selected },
                        BufferLineDiagnostic = { fg = foreground, bg = raised },
                        BufferLineDiagnosticVisible = { fg = foreground, bg = raised },
                        BufferLineDiagnosticSelected = { fg = selected_fg, bg = selected, bold = true },
                        BufferLineDiagnosticError = { fg = red, bg = raised, bold = true },
                        BufferLineDiagnosticErrorVisible = { fg = red, bg = raised, bold = true },
                        BufferLineDiagnosticErrorSelected = { fg = red, bg = selected, bold = true },
                        BufferLineDiagnosticWarning = { fg = yellow, bg = raised, bold = true },
                        BufferLineDiagnosticWarningVisible = { fg = yellow, bg = raised, bold = true },
                        BufferLineDiagnosticWarningSelected = { fg = yellow, bg = selected, bold = true },
                        BufferLineDiagnosticInfo = { fg = blue, bg = raised, bold = true },
                        BufferLineDiagnosticInfoVisible = { fg = blue, bg = raised, bold = true },
                        BufferLineDiagnosticInfoSelected = { fg = blue, bg = selected, bold = true },
                        BufferLineDiagnosticHint = { fg = green, bg = raised, bold = true },
                        BufferLineDiagnosticHintVisible = { fg = green, bg = raised, bold = true },
                        BufferLineDiagnosticHintSelected = { fg = green, bg = selected, bold = true },
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
                        WhichKey = { fg = foreground, bg = raised },
                        WhichKeyNormal = { fg = foreground, bg = raised },
                        WhichKeyDesc = { fg = foreground, bg = raised, bold = false, italic = false },
                        WhichKeyGroup = { fg = foreground, bg = raised, bold = false, italic = false },
                        WhichKeySeparator = { fg = foreground, bg = raised, bold = false, italic = false },
                        WhichKeyValue = { fg = foreground, bg = raised, bold = false, italic = false },
                        WhichKeyIcon = { fg = foreground, bg = raised, bold = false, italic = false },
                        WhichKeyBorder = { fg = border, bg = raised },
                        WhichKeyTitle = { fg = blue, bg = raised, bold = true },
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
                            if group:match("Selected$") and group:match("Diagnostic") then
                                fg = group:match("Error") and red
                                    or group:match("Warning") and yellow
                                    or group:match("Info") and blue
                                    or group:match("Hint") and green
                                    or foreground
                            end
                            vim.api.nvim_set_hl(0, group, { fg = fg, bg = bg })
                        end
                    end
                    for _, name in ipairs({
                        "BufferLineBufferSelected", "BufferLineTabSelected", "BufferLineNumbersSelected",
                        "BufferLineIconSelected", "BufferLineDevIconDefaultSelected", "BufferLineDiagnosticSelected",
                        "BufferLineDiagnosticErrorSelected", "BufferLineDiagnosticWarningSelected",
                        "BufferLineDiagnosticInfoSelected", "BufferLineDiagnosticHintSelected",
                        "BufferLineModifiedSelected", "BufferLineDuplicateSelected", "BufferLineCloseButtonSelected",
                    }) do
                        local current = vim.api.nvim_get_hl(0, { name = name, link = false })
                        current.bg = selected
                        vim.api.nvim_set_hl(0, name, current)
                    end
                    for _, group in ipairs(vim.fn.getcompletion("BufferLine", "highlight")) do
                        if group:match("Selected$") then
                            local current = vim.api.nvim_get_hl(0, { name = group, link = false })
                            current.bg = selected
                            if group:match("Numbers") or group:match("Indicator") then
                                current.fg = selected_accent
                            elseif group:match("DiagnosticError") then
                                current.fg = red
                            elseif group:match("DiagnosticWarning") then
                                current.fg = yellow
                            elseif group:match("DiagnosticInfo") then
                                current.fg = blue
                            elseif group:match("DiagnosticHint") then
                                current.fg = green
                            end
                            vim.api.nvim_set_hl(0, group, current)
                        end
                    end
                    for _, group in ipairs({
                        "WhichKey", "WhichKeyNormal", "WhichKeyDesc", "WhichKeyGroup",
                        "WhichKeySeparator", "WhichKeyValue", "WhichKeyIcon", "WhichKeyIconAzure",
                        "WhichKeyIconBlue", "WhichKeyIconCyan", "WhichKeyIconGreen", "WhichKeyIconGrey",
                        "WhichKeyIconOrange", "WhichKeyIconPurple", "WhichKeyIconRed", "WhichKeyIconYellow",
                        "WhichKeyTitle",
                    }) do
                        local current = vim.api.nvim_get_hl(0, { name = group, link = false })
                        vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", current, {
                            fg = foreground,
                            bg = raised,
                            bold = false,
                            italic = false,
                        }))
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
                    -- Bufferline composes selected diagnostics over its tab
                    -- surface. Keep count backgrounds transparent so the
                    -- selected tab surface remains uniform.
                    for _, severity in ipairs({ "Error", "Warning", "Info", "Hint" }) do
                        for _, state in ipairs({ "", "Visible", "Selected" }) do
                            local name = "BufferLineDiagnostic" .. severity .. state
                            local current = vim.api.nvim_get_hl(0, { name = name, link = false })
                            current.bg = nil
                            vim.api.nvim_set_hl(0, name, current)
                        end
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
                                bg = ({ normal = blue, insert = green, visual = visual, replace = red, command = orange, inactive = raised })[mode]
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
                    if vim.g.colors_name == "amoled" or vim.g.colors_name == "solarized" or vim.g.colors_name == "purelight" then
                        vim.schedule(apply_theme_links)
                    end
                end,
                desc = "Reapply AMOLED plugin highlights after buffer UI setup",
            })

            local themes = {
                { name = "Solarized Dark", colorscheme = "solarized", background = "dark", key = "solarized-dark" },
                { name = "Solarized Light", colorscheme = "solarized", background = "light", key = "solarized-light" },
                { name = "Pure Light", colorscheme = "purelight", background = "light" },
                { name = "Catppuccin Latte", colorscheme = "catppuccin-latte", flavour = "latte" },
                { name = "Catppuccin Frappé", colorscheme = "catppuccin-frappe", flavour = "frappe" },
                { name = "Catppuccin Macchiato", colorscheme = "catppuccin-macchiato", flavour = "macchiato" },
                { name = "Catppuccin Mocha", colorscheme = "catppuccin-mocha", flavour = "mocha" },
                { name = "AMOLED Black", colorscheme = "amoled" },
            }
            for _, theme in ipairs(themes) do
                theme.key = theme.key or theme.colorscheme
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
                vim.o.background = choice.background or (choice.flavour == "latte" and "light" or "dark")
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
                apply_theme(themes[7])
            end
        end,
    },
}
