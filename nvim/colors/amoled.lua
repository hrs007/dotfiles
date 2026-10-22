vim.o.background = "dark"
vim.o.termguicolors = true
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end
vim.g.colors_name = "amoled"

vim.g.terminal_color_0 = "#000000"
vim.g.terminal_color_1 = "#ff6b7a"
vim.g.terminal_color_2 = "#70e1a1"
vim.g.terminal_color_3 = "#f5d76e"
vim.g.terminal_color_4 = "#78a9ff"
vim.g.terminal_color_5 = "#c49bff"
vim.g.terminal_color_6 = "#5eddeb"
vim.g.terminal_color_7 = "#c0c7d2"
vim.g.terminal_color_8 = "#68758a"
vim.g.terminal_color_9 = "#ff8792"
vim.g.terminal_color_10 = "#8aefb2"
vim.g.terminal_color_11 = "#ffe58a"
vim.g.terminal_color_12 = "#91b8ff"
vim.g.terminal_color_13 = "#d2b2ff"
vim.g.terminal_color_14 = "#7be6f0"
vim.g.terminal_color_15 = "#f3f4f6"

local palette = {
    black = "#000000",
    surface = "#000000",
    surface_alt = "#151922",
    surface_raised = "#0c1018",
    surface_high = "#1d2430",
    border = "#68758a",
    foreground = "#f3f4f6",
    muted = "#c0c7d2",
    subtle = "#8994a5",
    red = "#ff6b7a",
    orange = "#ffad66",
    yellow = "#f5d76e",
    green = "#70e1a1",
    cyan = "#5eddeb",
    blue = "#78a9ff",
    purple = "#c49bff",
}

-- Brighten secondary UI copy as well as primary text. These are intentionally
-- lighter than the editor's line-number gray for reliable readability.
local readable = palette.muted
local secondary = "#b7c1d0"

local set = vim.api.nvim_set_hl
local function hl(name, spec)
    set(0, name, spec)
end

-- Keep every panel and menu on the same true-black canvas. Only active rows
-- use a subtle near-black fill so selection remains visible.
hl("Normal", { fg = palette.foreground, bg = palette.black })
hl("NormalNC", { fg = palette.foreground, bg = palette.black })
hl("EndOfBuffer", { fg = palette.black, bg = palette.black })
hl("MsgArea", { fg = palette.foreground, bg = palette.black })
hl("NormalFloat", { fg = palette.foreground, bg = palette.surface_raised })
hl("FloatBorder", { fg = palette.border, bg = palette.surface_raised })
hl("FloatTitle", { fg = palette.blue, bg = palette.surface_raised, bold = true })
hl("Cursor", { fg = palette.black, bg = palette.foreground })
hl("CursorLine", { bg = palette.surface_alt })
hl("CursorColumn", { bg = palette.surface_alt })
hl("CursorLineNr", { fg = palette.blue, bg = palette.surface_alt, bold = true })
hl("LineNr", { fg = palette.subtle, bg = palette.black })
hl("SignColumn", { bg = palette.black })
hl("FoldColumn", { fg = palette.subtle, bg = palette.black })
hl("ColorColumn", { bg = palette.surface_alt })
hl("WinSeparator", { fg = palette.border, bg = palette.black })
hl("StatusLine", { fg = palette.foreground, bg = palette.surface_high, bold = true })
hl("StatusLineNC", { fg = palette.muted, bg = palette.surface_raised })
hl("WinBar", { fg = palette.foreground, bg = palette.black })
hl("WinBarNC", { fg = palette.muted, bg = palette.black })
hl("TabLine", { fg = palette.muted, bg = palette.surface_raised })
hl("TabLineSel", { fg = palette.foreground, bg = palette.surface_high, bold = true, underline = true, sp = palette.blue })
hl("TabLineFill", { bg = palette.black })
hl("Pmenu", { fg = palette.foreground, bg = palette.surface_raised })
hl("PmenuSel", { fg = palette.foreground, bg = palette.surface_high, bold = true })
hl("PmenuSbar", { bg = palette.surface_alt })
hl("PmenuThumb", { bg = palette.muted })
hl("Visual", { bg = palette.surface_high })
hl("VisualNOS", { bg = palette.surface_high, underline = true, sp = palette.border })
hl("QuickFixLine", { fg = palette.foreground, bg = palette.surface_high, bold = true })
hl("Folded", { fg = palette.foreground, bg = palette.black })
hl("Conceal", { fg = palette.subtle, bg = palette.black })
hl("SpellBad", { undercurl = true, sp = palette.red })
hl("SpellCap", { undercurl = true, sp = palette.blue })
hl("SpellRare", { undercurl = true, sp = palette.purple })
hl("SpellLocal", { undercurl = true, sp = palette.cyan })
hl("Search", { fg = palette.black, bg = palette.yellow, bold = true })
hl("IncSearch", { fg = palette.black, bg = palette.orange, bold = true })
hl("MatchParen", { fg = palette.yellow, bg = palette.surface_high, bold = true, underline = true, sp = palette.yellow })
hl("Whitespace", { fg = "#68758a" })
hl("WinBar", { fg = palette.foreground, bg = palette.black, bold = true })
hl("NonText", { fg = palette.subtle })
hl("SpecialKey", { fg = palette.subtle })
hl("Directory", { fg = palette.blue })
hl("Title", { fg = palette.blue, bold = true })
hl("Question", { fg = palette.green })
hl("MoreMsg", { fg = palette.green })
hl("WarningMsg", { fg = palette.yellow })
hl("ErrorMsg", { fg = palette.red, bold = true })
hl("Question", { fg = palette.green, bold = true })
hl("ModeMsg", { fg = readable, bold = true })
hl("MoreMsg", { fg = palette.green, bold = true })
hl("WarningMsg", { fg = palette.yellow, bold = true })
hl("MsgSeparator", { fg = palette.border, bg = palette.black })
hl("StatusLineTerm", { fg = palette.foreground, bg = palette.surface_high, bold = true })
hl("StatusLineTermNC", { fg = palette.muted, bg = palette.surface_raised })
hl("TabLine", { fg = readable, bg = palette.surface_raised })
hl("WinBarNC", { fg = secondary, bg = palette.black })
hl("FoldColumn", { fg = secondary, bg = palette.black })
hl("Conceal", { fg = secondary, bg = palette.black })
hl("NonText", { fg = secondary })
hl("SpecialKey", { fg = secondary })
hl("Whitespace", { fg = secondary })
hl("DiagnosticUnnecessary", { fg = secondary, italic = true })
hl("DiagnosticDeprecated", { fg = secondary, strikethrough = true })
hl("LspInlayHint", { fg = secondary, bg = palette.surface_raised, italic = true })
hl("FloatFooter", { fg = secondary, bg = palette.surface_raised, italic = true })

-- Syntax colors retain high contrast against the black editor background.
hl("Comment", { fg = palette.muted, italic = true })
hl("Constant", { fg = palette.orange })
hl("String", { fg = palette.green })
hl("Character", { fg = palette.green })
hl("Number", { fg = palette.orange })
hl("Boolean", { fg = palette.orange })
hl("Float", { fg = palette.orange })
hl("Identifier", { fg = palette.foreground })
hl("Function", { fg = palette.blue })
hl("Statement", { fg = palette.purple })
hl("Conditional", { fg = palette.purple })
hl("Repeat", { fg = palette.purple })
hl("Label", { fg = palette.cyan })
hl("Operator", { fg = palette.cyan })
hl("Keyword", { fg = palette.purple })
hl("Exception", { fg = palette.red })
hl("PreProc", { fg = palette.cyan })
hl("Include", { fg = palette.cyan })
hl("Define", { fg = palette.cyan })
hl("Macro", { fg = palette.cyan })
hl("Type", { fg = palette.yellow })
hl("StorageClass", { fg = palette.purple })
hl("Structure", { fg = palette.yellow })
hl("Typedef", { fg = palette.yellow })
hl("Special", { fg = palette.cyan })
hl("SpecialChar", { fg = palette.orange })
hl("Tag", { fg = palette.red })
hl("Delimiter", { fg = palette.foreground })
hl("SpecialComment", { fg = palette.muted, italic = true })
hl("Debug", { fg = palette.red })
hl("Underlined", { fg = palette.blue, underline = true })
hl("Ignore", { fg = palette.muted })
hl("Error", { fg = palette.red, undercurl = true })
hl("Todo", { fg = palette.black, bg = palette.yellow, bold = true })
hl("NvimInternalError", { fg = palette.red, bg = palette.black, bold = true })
hl("NvimFigureBrace", { fg = palette.cyan, bg = palette.black })
hl("NvimSingleQuotedUnknownEscape", { fg = palette.red, bg = palette.black, bold = true })
hl("NvimInvalidSingleQuotedUnknownEscape", { fg = palette.red, bg = palette.black, bold = true })

-- LSP diagnostics, diffs, and common Git signs also use the same palette.
hl("DiagnosticError", { fg = palette.red })
hl("DiagnosticWarn", { fg = palette.yellow })
hl("DiagnosticInfo", { fg = palette.blue })
hl("DiagnosticHint", { fg = palette.cyan })
hl("DiagnosticOk", { fg = palette.green })
hl("DiagnosticVirtualTextError", { fg = palette.red, bg = "#19080d" })
hl("DiagnosticVirtualTextWarn", { fg = palette.yellow, bg = "#191407" })
hl("DiagnosticVirtualTextInfo", { fg = palette.blue, bg = "#0a1020" })
hl("DiagnosticVirtualTextHint", { fg = palette.cyan, bg = "#071619" })
hl("DiagnosticSignError", { fg = palette.red, bg = palette.black })
hl("DiagnosticSignWarn", { fg = palette.yellow, bg = palette.black })
hl("DiagnosticSignInfo", { fg = palette.blue, bg = palette.black })
hl("DiagnosticSignHint", { fg = palette.cyan, bg = palette.black })
hl("DiagnosticUnderlineError", { undercurl = true, sp = palette.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = palette.yellow })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = palette.blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = palette.cyan })
hl("DiffAdd", { fg = palette.green, bg = "#08170e" })
hl("DiffChange", { fg = palette.blue, bg = "#0b1425" })
hl("DiffDelete", { fg = palette.red, bg = "#1b0a10" })
hl("DiffText", { fg = palette.yellow, bg = "#211a08", bold = true })
hl("Added", { fg = palette.green })
hl("Changed", { fg = palette.blue })
hl("Removed", { fg = palette.red })
hl("GitSignsAdd", { fg = palette.green, bg = palette.black })
hl("GitSignsChange", { fg = palette.blue, bg = palette.black })
hl("GitSignsDelete", { fg = palette.red, bg = palette.black })
hl("GitSignsChangedelete", { fg = palette.orange, bg = palette.black })
hl("GitSignsTopdelete", { fg = palette.orange, bg = palette.black })
hl("GitSignsUntracked", { fg = palette.cyan, bg = palette.black })
hl("GitSignsCurrentLineBlame", { fg = palette.subtle, italic = true })
hl("DiffAdded", { fg = palette.green, bg = "#08170e" })
hl("DiffRemoved", { fg = palette.red, bg = "#1b0a10" })
hl("DiffFile", { fg = palette.blue, bold = true })
hl("DiffIndexLine", { fg = palette.purple })

-- Explicit modern Tree-sitter captures keep syntax colors consistent even
-- when a parser does not fall back to the traditional syntax groups.
hl("@comment", { link = "Comment" })
hl("@string", { link = "String" })
hl("@character", { link = "Character" })
hl("@number", { link = "Number" })
hl("@boolean", { link = "Boolean" })
hl("@constant", { link = "Constant" })
hl("@constant.builtin", { fg = palette.orange, italic = true })
hl("@function", { link = "Function" })
hl("@function.call", { link = "Function" })
hl("@method", { link = "Function" })
hl("@method.call", { link = "Function" })
hl("@keyword", { link = "Keyword" })
hl("@keyword.function", { link = "Keyword" })
hl("@operator", { link = "Operator" })
hl("@type", { link = "Type" })
hl("@type.builtin", { fg = palette.yellow, italic = true })
hl("@variable", { link = "Identifier" })
hl("@variable.builtin", { fg = palette.cyan, italic = true })
hl("@parameter", { fg = palette.foreground })
hl("@property", { fg = palette.cyan })
hl("@field", { fg = palette.cyan })
hl("@attribute", { fg = palette.purple })
hl("@punctuation.delimiter", { fg = palette.muted })
hl("@punctuation.bracket", { fg = palette.foreground })
hl("@tag", { link = "Tag" })
hl("@tag.attribute", { fg = palette.cyan })
hl("@tag.delimiter", { fg = palette.muted })
hl("@markup.heading", { fg = palette.blue, bold = true })
hl("@markup.heading.1.delimiter.vimdoc", { fg = palette.blue, bg = palette.black, bold = true })
hl("@markup.heading.2.delimiter.vimdoc", { fg = palette.blue, bg = palette.black, bold = true })
hl("@markup.link", { fg = palette.cyan, underline = true })
hl("@markup.raw", { fg = palette.green })
hl("@markup.list", { fg = palette.orange })

-- Consistent surfaces for the plugins used by this Neovim setup.
for group, spec in pairs({
    TelescopePromptCounter = { fg = palette.cyan, bg = palette.surface_raised, bold = true },
    TelescopeResultsClass = { fg = palette.yellow },
    TelescopeResultsStruct = { fg = palette.yellow },
    TelescopeResultsFunction = { fg = palette.blue },
    TelescopeResultsMethod = { fg = palette.blue },
    TelescopeResultsField = { fg = palette.cyan },
    TelescopeResultsVariable = { fg = palette.foreground },
    TelescopeResultsLineNr = { fg = secondary },
    TelescopeResultsIdentifier = { fg = palette.cyan },
    TelescopePreviewLine = { bg = palette.surface_alt },
    TelescopePreviewMatch = { fg = palette.yellow, bold = true },
    TelescopeNormal = { fg = palette.foreground, bg = palette.surface_raised },
    TelescopePromptNormal = { fg = palette.foreground, bg = palette.surface_raised },
    TelescopeResultsNormal = { fg = palette.foreground, bg = palette.surface_raised },
    TelescopePreviewNormal = { fg = palette.foreground, bg = palette.surface_raised },
    TelescopeBorder = { fg = palette.border, bg = palette.surface_raised },
    TelescopePromptBorder = { fg = palette.border, bg = palette.surface_raised },
    TelescopeResultsBorder = { fg = palette.border, bg = palette.surface_raised },
    TelescopePreviewBorder = { fg = palette.border, bg = palette.surface_raised },
    TelescopeSelection = { fg = palette.foreground, bg = palette.surface_high, bold = true },
    TelescopeMatching = { fg = palette.yellow, bold = true },
    TelescopePromptPrefix = { fg = palette.cyan, bold = true },
    TelescopeSelectionCaret = { fg = palette.blue, bg = palette.surface_high, bold = true },
    WhichKey = { fg = palette.foreground, bg = palette.surface_raised },
    WhichKeyNormal = { fg = palette.foreground, bg = palette.surface_raised },
    WhichKeyBorder = { fg = palette.border, bg = palette.surface_raised },
    WhichKeyTitle = { fg = palette.blue, bg = palette.surface_raised, bold = true },
    NotifyBackground = { fg = palette.foreground, bg = palette.surface_raised },
    NotifyERRORBorder = { fg = palette.red, bg = palette.surface_raised },
    NotifyWARNBorder = { fg = palette.yellow, bg = palette.surface_raised },
    NotifyINFOBorder = { fg = palette.blue, bg = palette.surface_raised },
    NotifyDEBUGBorder = { fg = palette.muted, bg = palette.surface_raised },
    NotifyTRACEBorder = { fg = palette.cyan, bg = palette.surface_raised },
    BlinkCmpMenu = { fg = palette.foreground, bg = palette.surface_raised },
    BlinkCmpMenuBorder = { fg = palette.border, bg = palette.surface_raised },
    BlinkCmpDoc = { fg = palette.foreground, bg = palette.surface_raised },
    BlinkCmpDocBorder = { fg = palette.border, bg = palette.surface_raised },
    BlinkCmpSignatureHelp = { fg = palette.foreground, bg = palette.surface_raised },
    BlinkCmpSignatureHelpBorder = { fg = palette.border, bg = palette.surface_raised },
    BlinkCmpLabelMatch = { fg = palette.blue, bold = true },
    BlinkCmpLabelDescription = { fg = secondary, bg = palette.surface_raised },
    BlinkCmpKind = { fg = palette.cyan, bg = palette.surface_raised },
    TroubleNormal = { fg = palette.foreground, bg = palette.surface_raised },
    TroubleNormalNC = { fg = palette.foreground, bg = palette.surface_raised },
    NoicePopup = { fg = palette.foreground, bg = palette.surface_raised },
    NoicePopupBorder = { fg = palette.border, bg = palette.surface_raised },
    NoiceCmdlinePopup = { fg = palette.foreground, bg = palette.surface_raised },
    NoiceCmdlinePopupBorder = { fg = palette.border, bg = palette.surface_raised },
    NoicePopupmenu = { fg = palette.foreground, bg = palette.surface_raised },
    NoicePopupmenuBorder = { fg = palette.border, bg = palette.surface_raised },
    NoicePopupmenuSelected = { fg = palette.foreground, bg = palette.surface_high, bold = true },
    MiniStatuslineFilename = { fg = palette.foreground, bg = palette.surface_high },
    MiniStatuslineDevinfo = { fg = palette.foreground, bg = palette.surface_raised },
    MiniStatuslineFileinfo = { fg = palette.foreground, bg = palette.surface_raised },
    MiniStatuslineModeNormal = { fg = palette.black, bg = palette.blue, bold = true },
    MiniStatuslineModeInsert = { fg = palette.black, bg = palette.green, bold = true },
    MiniStatuslineModeVisual = { fg = palette.black, bg = palette.purple, bold = true },
    MiniStatuslineModeCommand = { fg = palette.black, bg = palette.orange, bold = true },
}) do
    hl(group, spec)
end

