-- A neutral, paper-white theme with crisp ink and accessible semantic colors.
vim.o.background = "light"
vim.o.termguicolors = true
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "purelight"

local p = {
    bg = "#ffffff", surface = "#f4f6f8", surface2 = "#e9edf2", ink = "#17212b",
    muted = "#526170", subtle = "#657382", border = "#aab5c1", blue = "#0759a5",
    cyan = "#006b73", green = "#287a35", yellow = "#8a5b00", orange = "#a64000",
    red = "#b42332", purple = "#7041a6", magenta = "#a12d79",
}
local set = vim.api.nvim_set_hl
local function hl(name, spec) set(0, name, spec) end

hl("Normal", { fg = p.ink, bg = p.bg })
hl("NormalNC", { fg = p.ink, bg = p.bg })
hl("EndOfBuffer", { fg = p.bg, bg = p.bg })
hl("MsgArea", { fg = p.ink, bg = p.bg })
hl("NormalFloat", { fg = p.ink, bg = p.surface })
hl("FloatBorder", { fg = p.border, bg = p.surface })
hl("FloatTitle", { fg = p.blue, bg = p.surface, bold = true })
hl("Cursor", { fg = p.bg, bg = p.ink })
hl("CursorLine", { bg = p.surface })
hl("CursorColumn", { bg = p.surface })
hl("CursorLineNr", { fg = p.blue, bg = p.surface, bold = true })
hl("LineNr", { fg = p.subtle, bg = p.bg })
hl("SignColumn", { bg = p.bg })
hl("FoldColumn", { fg = p.subtle, bg = p.bg })
hl("ColorColumn", { bg = p.surface })
hl("WinSeparator", { fg = p.border, bg = p.bg })
hl("StatusLine", { fg = p.ink, bg = p.surface2, bold = true })
hl("StatusLineNC", { fg = p.muted, bg = p.surface })
hl("WinBar", { fg = p.ink, bg = p.bg })
hl("WinBarNC", { fg = p.muted, bg = p.bg })
hl("TabLine", { fg = p.muted, bg = p.surface })
hl("TabLineSel", { fg = p.bg, bg = p.blue, bold = true })
hl("TabLineFill", { bg = p.bg })
hl("Pmenu", { fg = p.ink, bg = p.surface })
hl("PmenuSel", { fg = p.bg, bg = p.blue, bold = true })
hl("PmenuSbar", { bg = p.surface2 })
hl("PmenuThumb", { bg = p.border })
hl("Visual", { bg = "#d9e9f7" })
hl("VisualNOS", { bg = "#d9e9f7", underline = true, sp = p.blue })
hl("QuickFixLine", { fg = p.ink, bg = p.surface2, bold = true })
hl("Folded", { fg = p.muted, bg = p.surface })
hl("Conceal", { fg = p.subtle })
hl("Search", { fg = p.ink, bg = "#ffe58a", bold = true })
hl("IncSearch", { fg = p.ink, bg = "#ffbd80", bold = true })
hl("MatchParen", { fg = p.blue, bg = "#e3effa", bold = true, underline = true, sp = p.blue })
hl("Whitespace", { fg = p.border })
hl("NonText", { fg = p.subtle })
hl("SpecialKey", { fg = p.subtle })
hl("Directory", { fg = p.blue, bold = true })
hl("Title", { fg = p.blue, bold = true })
hl("Question", { fg = p.green, bold = true })
hl("MoreMsg", { fg = p.green, bold = true })
hl("WarningMsg", { fg = p.orange, bold = true })
hl("ErrorMsg", { fg = p.red, bold = true })
hl("Comment", { fg = p.muted, italic = true })
hl("Constant", { fg = p.orange })
hl("String", { fg = p.green })
hl("Character", { fg = p.green })
hl("Number", { fg = p.purple })
hl("Boolean", { fg = p.purple })
hl("Float", { fg = p.purple })
hl("Identifier", { fg = p.ink })
hl("Function", { fg = p.blue, bold = true })
hl("Statement", { fg = p.purple })
hl("Conditional", { fg = p.purple })
hl("Repeat", { fg = p.purple })
hl("Label", { fg = p.cyan })
hl("Operator", { fg = p.cyan })
hl("Keyword", { fg = p.purple })
hl("Exception", { fg = p.red })
hl("PreProc", { fg = p.orange })
hl("Include", { fg = p.orange })
hl("Define", { fg = p.orange })
hl("Macro", { fg = p.orange })
hl("Type", { fg = p.yellow })
hl("StorageClass", { fg = p.purple })
hl("Structure", { fg = p.yellow })
hl("Typedef", { fg = p.yellow })
hl("Special", { fg = p.cyan })
hl("Delimiter", { fg = p.muted })
hl("Underlined", { fg = p.blue, underline = true })
hl("Added", { fg = p.green })
hl("Changed", { fg = p.yellow })
hl("Removed", { fg = p.red })
hl("DiffAdd", { bg = "#e3f2df" })
hl("DiffChange", { bg = "#e3eff8" })
hl("DiffDelete", { fg = p.red, bg = "#f8e3e2" })
hl("DiffText", { bg = "#cfe3f2", bold = true })
hl("DiagnosticError", { fg = p.red })
hl("DiagnosticWarn", { fg = p.orange })
hl("DiagnosticInfo", { fg = p.blue })
hl("DiagnosticHint", { fg = p.cyan })
hl("DiagnosticOk", { fg = p.green })
hl("DiagnosticUnderlineError", { undercurl = true, sp = p.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = p.orange })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = p.blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = p.cyan })
hl("DiagnosticUnnecessary", { fg = p.subtle, italic = true })
hl("DiagnosticDeprecated", { strikethrough = true, sp = p.red })
hl("LspInlayHint", { fg = p.muted, bg = p.surface, italic = true })
hl("GitSignsAdd", { fg = p.green, bg = p.bg })
hl("GitSignsChange", { fg = p.blue, bg = p.bg })
hl("GitSignsDelete", { fg = p.red, bg = p.bg })

for capture, target in pairs({
    ["@comment"] = "Comment", ["@string"] = "String", ["@character"] = "Character",
    ["@number"] = "Number", ["@boolean"] = "Boolean", ["@constant"] = "Constant",
    ["@function"] = "Function", ["@function.call"] = "Function", ["@method"] = "Function",
    ["@keyword"] = "Keyword", ["@operator"] = "Operator", ["@type"] = "Type",
    ["@variable"] = "Identifier", ["@property"] = "Identifier", ["@attribute"] = "PreProc",
    ["@punctuation.delimiter"] = "Delimiter", ["@punctuation.bracket"] = "Delimiter",
    ["@markup.heading"] = "Title", ["@markup.link"] = "Underlined", ["@markup.raw"] = "String",
}) do hl(capture, { link = target }) end

for group, target in pairs({
    TelescopeNormal = "NormalFloat", TelescopeBorder = "FloatBorder", TelescopePromptBorder = "FloatBorder",
    TelescopeResultsBorder = "FloatBorder", TelescopePreviewBorder = "FloatBorder", TelescopeSelection = "PmenuSel",
    BlinkCmpMenu = "Pmenu", BlinkCmpMenuBorder = "FloatBorder", BlinkCmpDoc = "NormalFloat", BlinkCmpDocBorder = "FloatBorder",
    NoicePopup = "NormalFloat", NoicePopupBorder = "FloatBorder", NoiceCmdlinePopup = "NormalFloat",
    NoiceCmdlinePopupBorder = "FloatBorder", WhichKeyNormal = "NormalFloat", WhichKeyBorder = "FloatBorder",
    TroubleNormal = "NormalFloat", TroubleNormalNC = "NormalFloat", OilDir = "Directory", OilFile = "Normal",
}) do hl(group, { link = target }) end

for i, color in ipairs({ p.ink, p.red, p.green, p.yellow, p.blue, p.magenta, p.cyan, p.muted,
    p.subtle, p.red, p.green, p.yellow, p.blue, p.magenta, p.cyan, p.bg }) do
    vim.g["terminal_color_" .. (i - 1)] = color
end
