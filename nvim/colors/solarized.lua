-- Solarized Dark and Solarized Light, with the canonical Solarized palette.
vim.o.termguicolors = true
vim.o.background = vim.o.background == "light" and "light" or "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "solarized"

local dark = vim.o.background == "dark"
local p = {
    base03 = "#002b36", base02 = "#073642", base01 = "#586e75", base00 = "#657b83",
    base0 = "#839496", base1 = "#93a1a1", base2 = "#eee8d5", base3 = "#fdf6e3",
    yellow = "#b58900", orange = "#cb4b16", red = "#dc322f", magenta = "#d33682",
    violet = "#6c71c4", blue = "#268bd2", cyan = "#2aa198", green = "#859900",
}
local bg, bg_alt, fg, muted = dark and p.base03 or p.base3, dark and p.base02 or p.base2, dark and p.base0 or p.base00, dark and p.base01 or p.base1
local set = vim.api.nvim_set_hl
local function hl(name, spec) set(0, name, spec) end

hl("Normal", { fg = fg, bg = bg })
hl("NormalNC", { fg = fg, bg = bg })
hl("EndOfBuffer", { fg = bg_alt, bg = bg })
hl("MsgArea", { fg = fg, bg = bg })
hl("NormalFloat", { fg = fg, bg = bg_alt })
hl("FloatBorder", { fg = muted, bg = bg_alt })
hl("FloatTitle", { fg = p.blue, bg = bg_alt, bold = true })
hl("Cursor", { fg = bg, bg = fg })
hl("CursorLine", { bg = bg_alt })
hl("CursorColumn", { bg = bg_alt })
hl("CursorLineNr", { fg = p.yellow, bg = bg_alt, bold = true })
hl("LineNr", { fg = muted, bg = bg })
hl("SignColumn", { bg = bg })
hl("FoldColumn", { fg = muted, bg = bg })
hl("ColorColumn", { bg = bg_alt })
hl("WinSeparator", { fg = muted, bg = bg })
hl("StatusLine", { fg = fg, bg = bg_alt, bold = true })
hl("StatusLineNC", { fg = muted, bg = bg })
hl("WinBar", { fg = fg, bg = bg })
hl("WinBarNC", { fg = muted, bg = bg })
hl("TabLine", { fg = muted, bg = bg_alt })
hl("TabLineSel", { fg = dark and p.base03 or p.base3, bg = p.blue, bold = true })
hl("TabLineFill", { bg = bg })
hl("Pmenu", { fg = fg, bg = bg_alt })
hl("PmenuSel", { fg = dark and p.base03 or p.base3, bg = p.blue, bold = true })
hl("PmenuSbar", { bg = bg_alt })
hl("PmenuThumb", { bg = muted })
hl("Visual", { bg = dark and "#174b55" or "#d8cfb5" })
hl("VisualNOS", { bg = dark and "#174b55" or "#d8cfb5", underline = true })
hl("QuickFixLine", { fg = fg, bg = bg_alt, bold = true })
hl("Folded", { fg = muted, bg = bg_alt })
hl("Conceal", { fg = muted })
hl("Search", { fg = p.base03, bg = p.yellow, bold = true })
hl("IncSearch", { fg = p.base03, bg = p.orange, bold = true })
hl("MatchParen", { fg = p.cyan, bg = bg_alt, bold = true, underline = true, sp = p.cyan })
hl("Whitespace", { fg = muted })
hl("NonText", { fg = muted })
hl("SpecialKey", { fg = muted })
hl("Directory", { fg = p.blue, bold = true })
hl("Title", { fg = p.blue, bold = true })
hl("Question", { fg = p.green, bold = true })
hl("MoreMsg", { fg = p.green, bold = true })
hl("WarningMsg", { fg = p.orange, bold = true })
hl("ErrorMsg", { fg = p.red, bold = true })
hl("Comment", { fg = muted, italic = true })
hl("Constant", { fg = p.cyan })
hl("String", { fg = p.cyan })
hl("Character", { fg = p.cyan })
hl("Number", { fg = p.magenta })
hl("Boolean", { fg = p.magenta })
hl("Float", { fg = p.magenta })
hl("Identifier", { fg = p.blue })
hl("Function", { fg = p.blue, bold = true })
hl("Statement", { fg = p.green })
hl("Conditional", { fg = p.green })
hl("Repeat", { fg = p.green })
hl("Label", { fg = p.yellow })
hl("Operator", { fg = p.base1 })
hl("Keyword", { fg = p.green })
hl("Exception", { fg = p.red })
hl("PreProc", { fg = p.orange })
hl("Include", { fg = p.orange })
hl("Define", { fg = p.orange })
hl("Macro", { fg = p.orange })
hl("Type", { fg = p.yellow })
hl("StorageClass", { fg = p.orange })
hl("Structure", { fg = p.yellow })
hl("Typedef", { fg = p.yellow })
hl("Special", { fg = p.orange })
hl("Delimiter", { fg = p.base1 })
hl("Underlined", { fg = p.blue, underline = true })
hl("Added", { fg = p.green })
hl("Changed", { fg = p.yellow })
hl("Removed", { fg = p.red })
hl("DiffAdd", { bg = dark and "#123f3a" or "#dce8c2" })
hl("DiffChange", { bg = dark and "#173c50" or "#d8e5ed" })
hl("DiffDelete", { fg = p.red, bg = dark and "#4b2528" or "#f1d5ce" })
hl("DiffText", { bg = dark and "#24546b" or "#c5dce8", bold = true })
hl("DiagnosticError", { fg = p.red })
hl("DiagnosticWarn", { fg = p.orange })
hl("DiagnosticInfo", { fg = p.blue })
hl("DiagnosticHint", { fg = p.cyan })
hl("DiagnosticOk", { fg = p.green })
hl("DiagnosticUnderlineError", { undercurl = true, sp = p.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = p.orange })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = p.blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = p.cyan })
hl("DiagnosticUnnecessary", { fg = muted, italic = true })
hl("DiagnosticDeprecated", { strikethrough = true, sp = p.red })
hl("LspInlayHint", { fg = muted, bg = bg_alt, italic = true })
hl("GitSignsAdd", { fg = p.green, bg = bg })
hl("GitSignsChange", { fg = p.blue, bg = bg })
hl("GitSignsDelete", { fg = p.red, bg = bg })

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

for i, color in ipairs({ dark and p.base03 or p.base3, p.red, p.green, p.yellow, p.blue, p.magenta, p.cyan, fg,
    muted, p.red, p.green, p.yellow, p.blue, p.magenta, p.cyan, dark and p.base0 or p.base00 }) do
    vim.g["terminal_color_" .. (i - 1)] = color
end
