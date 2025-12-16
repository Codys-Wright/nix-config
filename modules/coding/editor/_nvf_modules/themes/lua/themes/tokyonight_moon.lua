-- TokyoNight Moon theme for base46
-- Based on TokyoNight Moon color palette

local M = {}

M.base_30 = {
  white = "#c8d3f5", -- fg: white
  darker_black = "#1e2030", -- bg_dark: LSP/CMP Pop-ups, Tree BG
  black = "#222436", -- bg: CMP BG, Icons/Headers FG
  black2 = "#2f334d", -- bg_highlight: Tabline BG, Cursor Lines, Selections
  one_bg = "#3b4261", -- fg_gutter: Pop-up Menu BG, Statusline Icon FG
  one_bg2 = "#545c7e", -- dark3: Tabline Inactive BG, Indent Line Context Start
  one_bg3 = "#636da6", -- comment: Tabline Toggle/New Btn, Borders
  grey = "#737aa2", -- dark5: Line Nr, Scrollbar, Indent Line Hover
  grey_fg = "#636da6", -- comment: Comment
  grey_fg2 = "#828bb8", -- fg_dark: Unused
  light_grey = "#828bb8", -- fg_dark: Diff Change, Tabline Inactive FG
  red = "#ff757f", -- red: Diff Delete, Diag Error
  baby_pink = "#fca7ea", -- purple: Some Dev Icons
  pink = "#c099ff", -- magenta: Indicators
  line = "#3b4261", -- fg_gutter: Win Sep, Indent Line
  green = "#c3e88d", -- green: Diff Add, Diag Info, Indicators
  vibrant_green = "#4fd6be", -- green1: Some Dev Icons
  blue = "#82aaff", -- blue: UI Elements, Dev/CMP Icons
  nord_blue = "#65bcff", -- blue1: Indicators
  yellow = "#ffc777", -- yellow: Diag Warn
  sun = "#ff966c", -- orange: Sun
  purple = "#c099ff", -- magenta: Purple
  dark_purple = "#7c3aed", -- Derived darker purple
  teal = "#4fd6be", -- teal: Teal
  orange = "#ff966c", -- orange: Orange
  cyan = "#86e1fc", -- cyan: Cyan
  statusline_bg = "#1e2030", -- bg_dark: Statusline BG
  lightbg = "#2f334d", -- bg_highlight: Light BG
  pmenu_bg = "#2f334d", -- bg_highlight: Popup Menu BG
  folder_bg = "#65bcff", -- nord_blue/blue1: Folder BG (light blue)
}

M.base_16 = {
  base00 = "#222436", -- bg: Default Background
  base01 = "#2f334d", -- bg_highlight: Lighter Background
  base02 = "#3b4261", -- fg_gutter: Selection Background (Visual Mode)
  base03 = "#636da6", -- comment: Comments, Invisibles
  base04 = "#828bb8", -- fg_dark: Dark Foreground
  base05 = "#c8d3f5", -- fg: Default Foreground, Variable
  base06 = "#d9dce8", -- Light Foreground (derived)
  base07 = "#e2e8f0", -- Light Foreground, CMP Icons (derived)
  base08 = "#c099ff", -- magenta: Identifier, Statement (Character overridden to green in polish_hl)
  base09 = "#ff966c", -- orange: Constants, Numbers, Booleans
  base0A = "#65bcff", -- blue1: Type, Classes, Todo (PreProc overridden to cyan in polish_hl)
  base0B = "#c3e88d", -- green: Strings, Symbols
  base0C = "#65bcff", -- blue1: Special, Constructor
  base0D = "#82aaff", -- blue: Functions, Methods
  base0E = "#86e1fc", -- cyan: Keywords, Storage
  base0F = "#89ddff", -- blue5: Delimiters, SpecialChar
}

-- Override specific syntax highlighting to match tokyonight moon exactly
-- base46's syntax.lua maps:
--   Character=base08, Identifier=base08, Statement=base08
--   PreProc=base0A, Operator=base05, Include=base0D
-- But tokyonight moon uses:
--   Character=green, Identifier=magenta, Statement=magenta
--   PreProc=cyan, Operator=blue5, Include=blue
M.polish_hl = {
  defaults = {
    Character = { fg = "#c3e88d" }, -- green - override base08 (magenta) to match tokyonight
    Error = { fg = "#c53b53" }, -- red1 - error color
    ErrorMsg = { fg = "#c53b53" }, -- red1
    Operator = { fg = "#89ddff" }, -- blue5 - override base05 (default fg) to match tokyonight
    PreProc = { fg = "#86e1fc" }, -- cyan - override base0A (blue1) to match tokyonight
    Include = { fg = "#82aaff" }, -- blue - matches tokyonight (base46 uses base0D which is correct, but ensure it's blue)
    -- Hide end of buffer markers (~) by making them the same color as background
    EndOfBuffer = { fg = M.base_30.black }, -- bg: same as background to hide ~ characters
    -- Identifier and Statement will use base08 (magenta) which is correct
  },
  treesitter = {
    -- Variable parameter (function params like {inputs, ...}) should be yellow/orange
    ["@variable.parameter"] = { fg = "#ffc777" }, -- yellow - override base08 (magenta)
    -- Module/imports should have more contrast - use cyan instead of blue to stand out
    ["@module"] = { fg = "#86e1fc" }, -- cyan - more contrast than blue, stands out from other blue elements
    -- Keywords: Rust keywords like pub, mod, struct should be light purple with italic
    -- tokyonight uses purple (#fca7ea) for @keyword
    ["@keyword"] = { fg = "#fca7ea", italic = true }, -- light purple with italic - for pub, mod, struct, etc.
    ["@keyword.function"] = { fg = "#fca7ea", italic = true }, -- light purple with italic - override base0E (cyan)
    ["@keyword.return"] = { fg = "#4fd6be" }, -- green1/teal - match sea-green for return
    ["@keyword.operator"] = { fg = "#4fd6be" }, -- green1/teal - match sea-green
    ["@keyword.conditional"] = { fg = "#86e1fc" }, -- cyan - keep base0E (cyan) for conditionals
    ["@keyword.storage"] = { fg = "#fca7ea", italic = true }, -- light purple with italic - for struct, type, etc. in Rust
    -- Attributes like #[derive(...)] should be lighter blue (cyan)
    ["@attribute"] = { fg = "#65bcff" }, -- blue1 (lighter blue) - for derive and other attributes
    -- Properties should be sea-green (teal/green1)
    ["@property"] = { fg = "#4fd6be" }, -- green1/teal - override base08 (magenta)
    ["@variable.member"] = { fg = "#4fd6be" }, -- green1/teal - override base08 (magenta) - for field names like "templates"
    -- Constructor should be magenta, not blue1
    ["@constructor"] = { fg = "#c099ff" }, -- magenta - override base0C (blue1)
    -- String escape should be magenta, not blue1
    ["@string.escape"] = { fg = "#c099ff" }, -- magenta - override base0C (blue1)
    -- Type names like AppState, Tera should be light blue (blue1), not darker blue
    ["@type"] = { fg = "#65bcff" }, -- blue1 (light blue) - for type names like AppState, Tera
    ["@type.builtin"] = { fg = "#65bcff" }, -- blue1 (light blue) - for builtin types
    ["@type.definition"] = { fg = "#65bcff" }, -- blue1 (light blue) - for type definitions
    -- Operator should be blue5
    ["@operator"] = { fg = "#89ddff" }, -- blue5 - override base05 (default fg)
    -- Punctuation should match tokyonight
    ["@punctuation.bracket"] = { fg = "#828bb8" }, -- fg_dark - override base0F (blue5)
    ["@punctuation.delimiter"] = { fg = "#89ddff" }, -- blue5 - matches base0F
  },
}

M.type = "dark"

-- Custom colors for snacks picker (can be accessed via theme.snacks_picker)
M.snacks_picker = {
  border = M.base_30.black2,           -- bg_highlight: Border color
  background = M.base_30.black,        -- bg: Main background
  preview_title_bg = M.base_30.green,  -- green: Preview title background
  input_border = M.base_30.black2,    -- bg_highlight: Input border
  input_bg = M.base_30.black2,        -- bg_highlight: Input background
  input_search = M.base_30.red,       -- red: Search text color
}

M = require("base46").override_theme(M, "tokyonight_moon")

return M

