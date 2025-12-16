-- TokyoNight Moon theme for base46
-- Based on TokyoNight Moon color palette from tokyonight.nvim
-- Exact color mappings to match tokyonight.nvim syntax highlighting

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
  baby_pink = "#fca7ea", -- purple: Keywords, some icons
  pink = "#c099ff", -- magenta: Identifier, Statement, Constructor
  line = "#3b4261", -- fg_gutter: Win Sep, Indent Line
  green = "#c3e88d", -- green: Diff Add, Diag Info, Strings, Characters
  vibrant_green = "#4fd6be", -- green1/teal: Properties, Variable Members, Hints
  blue = "#82aaff", -- blue: UI Elements, Functions, Dev/CMP Icons
  nord_blue = "#65bcff", -- blue1: Type, Special, CMP Match
  blue2 = "#0db9d7", -- blue2/info: Info color, MiniIconsAzure
  yellow = "#ffc777", -- yellow: Diag Warn, Variable Parameters
  sun = "#ff966c", -- orange: Constants, Numbers, CursorLineNr
  purple = "#c099ff", -- magenta: Same as pink
  dark_purple = "#7c3aed", -- Derived darker purple (not used in tokyonight)
  teal = "#4fd6be", -- teal: Same as vibrant_green
  orange = "#ff966c", -- orange: Same as sun
  cyan = "#86e1fc", -- cyan: Keywords, PreProc
  statusline_bg = "#1e2030", -- bg_dark: Statusline BG
  lightbg = "#2f334d", -- bg_highlight: Light BG
  pmenu_bg = "#1e2030", -- bg_dark: Popup Menu BG (tokyonight uses bg_dark, not bg_highlight)
  folder_bg = "#82aaff", -- blue: Folder BG (matches Directory color)
}

M.base_16 = {
  base00 = "#222436", -- bg: Default Background
  base01 = "#2f334d", -- bg_highlight: Lighter Background
  base02 = "#3b4261", -- fg_gutter: Selection Background (Visual Mode)
  base03 = "#636da6", -- comment: Comments, Invisibles
  base04 = "#828bb8", -- fg_dark: Dark Foreground
  base05 = "#c8d3f5", -- fg: Default Foreground, Variable
  base06 = "#d9dce8", -- Light Foreground (derived, not in tokyonight)
  base07 = "#e2e8f0", -- Light Foreground, CMP Icons (derived, not in tokyonight)
  base08 = "#c099ff", -- magenta: Identifier, Statement (Character overridden to green in polish_hl)
  base09 = "#ff966c", -- orange: Constants, Numbers, Booleans
  base0A = "#65bcff", -- blue1: Type, Classes, Special (PreProc overridden to cyan in polish_hl)
  base0B = "#c3e88d", -- green: Strings, Symbols, Characters
  base0C = "#65bcff", -- blue1: Special, Constructor (overridden in polish_hl)
  base0D = "#82aaff", -- blue: Functions, Methods, Include
  base0E = "#86e1fc", -- cyan: Keywords, Storage (but @keyword uses purple in tokyonight)
  base0F = "#89ddff", -- blue5: Delimiters, Operators, SpecialChar
}

-- Comprehensive override to match tokyonight.nvim syntax highlighting exactly
-- base46's syntax.lua maps many groups, but tokyonight uses different colors
-- Using hex values directly to avoid cache resolution issues with string color names
M.polish_hl = {
  -- CMP-specific overrides: Separate icon colors from text colors
  -- The icon uses CmpItemKind* groups, text uses CmpItemAbbr (which is white)
  cmp = {
    -- Override icon colors only - text stays white via CmpItemAbbr
    CmpItemKindFunction = { fg = M.base_30.nord_blue }, -- nord_blue: icon only (overrides base0D)
    CmpItemKindMethod = { fg = M.base_30.nord_blue }, -- nord_blue: icon only (overrides base0D)
    -- Keep text color separate (CmpItemAbbr is already white in base46)
    CmpItemAbbr = { fg = M.base_30.white }, -- white: Ensure text stays white
  },
  -- Blink.cmp overrides (if using blink.cmp/atom_colored style)
  -- BlinkCmpKind* groups control icon colors in blink.cmp
  blink = {
    BlinkCmpKindFunction = { fg = M.base_30.nord_blue }, -- nord_blue: icon only (overrides base0D)
    BlinkCmpKindMethod = { fg = M.base_30.nord_blue }, -- nord_blue: icon only (overrides base0D)
    -- Text uses BlinkCmpLabel which is already white
    BlinkCmpLabel = { fg = M.base_30.white }, -- white: Ensure text stays white
  },
  defaults = {
    -- Basic syntax groups - using M.base_30 and M.base_16 color references
    Character = { fg = M.base_30.green }, -- green - override base08 (magenta) to match tokyonight
    Identifier = { fg = M.base_30.pink }, -- magenta - ensure it's magenta (base08 is correct)
    Statement = { fg = M.base_30.pink }, -- magenta - ensure it's magenta (base08 is correct)
    Operator = { fg = M.base_16.base0F }, -- blue5 - override base05 (default fg) to match tokyonight
    PreProc = { fg = M.base_30.cyan }, -- cyan - override base0A (blue1) to match tokyonight
    Include = { fg = M.base_30.blue }, -- blue - matches tokyonight (base46 uses base0D which is correct)
    Function = { fg = M.base_30.blue }, -- blue - ensure it's blue (base0D is correct)
    Type = { fg = M.base_30.nord_blue }, -- blue1 (nord_blue) - ensure it's blue1 (base0A is correct)
    String = { fg = M.base_30.green }, -- green - ensure it's green (base0B is correct)
    Constant = { fg = M.base_30.sun }, -- orange (sun) - ensure it's orange (base09 is correct)
    Comment = { fg = M.base_30.grey_fg, italic = true }, -- grey_fg: comment with italic
    Special = { fg = M.base_30.nord_blue }, -- blue1 (nord_blue) - ensure it's blue1 (base0C is correct)
    Keyword = { fg = M.base_30.cyan, italic = true }, -- cyan with italic (but @keyword uses purple)
    Error = { fg = "#c53b53" }, -- red1 - error color (specific color, not in base_30/base_16)
    ErrorMsg = { fg = "#c53b53" }, -- red1 - error color (specific color, not in base_30/base_16)
    -- Hide end of buffer markers (~) by making them the same color as background
    EndOfBuffer = { fg = M.base_30.black }, -- black: same as background to hide ~ characters
    -- Mini.icons color groups (used when mini.icons mocks nvim-web-devicons)
    -- Matching tokyonight.nvim's mini_icons.lua color mappings
    -- Note: MiniIconsBlue uses nord_blue instead of blue to differentiate icons from text
    MiniIconsGrey = { fg = M.base_30.white }, -- fg: default foreground
    MiniIconsPurple = { fg = M.base_30.baby_pink }, -- purple: keywords, some icons
    MiniIconsBlue = { fg = M.base_30.nord_blue }, -- nord_blue: icons (different from text which uses blue)
    MiniIconsAzure = { fg = M.base_30.blue2 }, -- blue2/info: azure color (matches tokyonight's info)
    MiniIconsCyan = { fg = M.base_30.teal }, -- teal: cyan/teal icons
    MiniIconsGreen = { fg = M.base_30.green }, -- green: green icons
    MiniIconsYellow = { fg = M.base_30.yellow }, -- yellow: yellow icons
    MiniIconsOrange = { fg = M.base_30.orange }, -- orange: orange icons
    MiniIconsRed = { fg = M.base_30.red }, -- red: red icons
  },
  -- DevIcon* overrides to match tokyonight color scheme
  -- These override base46's devicons.lua integration to use M.base_30 color references
  -- Matching the color scheme that mini.icons would use (when it replaces nvim-web-devicons)
  devicons = {
    -- Nord blue icons (most common): c, css, lua, toml, md, tsx, jsx
    DevIconc = { fg = M.base_30.nord_blue },
    DevIconcss = { fg = M.base_30.nord_blue },
    DevIconlua = { fg = M.base_30.nord_blue },
    DevIcontoml = { fg = M.base_30.nord_blue },
    DevIconMd = { fg = M.base_30.nord_blue },
    DevIconTSX = { fg = M.base_30.nord_blue },
    DevIconJSX = { fg = M.base_30.nord_blue },
    -- Cyan icons: deb, Dockerfile, py, Dart
    DevIcondeb = { fg = M.base_30.cyan },
    DevIconDockerfile = { fg = M.base_30.cyan },
    DevIconpy = { fg = M.base_30.cyan },
    DevIconDart = { fg = M.base_30.cyan },
    -- Baby pink: html
    DevIconhtml = { fg = M.base_30.baby_pink },
    -- Dark purple: jpeg, jpg, png
    DevIconjpeg = { fg = M.base_30.dark_purple },
    DevIconjpg = { fg = M.base_30.dark_purple },
    DevIconpng = { fg = M.base_30.dark_purple },
    -- Sun (orange-yellow): js, xz, zip
    DevIconjs = { fg = M.base_30.sun },
    DevIconxz = { fg = M.base_30.sun },
    DevIconzip = { fg = M.base_30.sun },
    -- Orange: kt, rpm, Zig, Java
    DevIconkt = { fg = M.base_30.orange },
    DevIconrpm = { fg = M.base_30.orange },
    DevIconZig = { fg = M.base_30.orange },
    DevIconJava = { fg = M.base_30.orange },
    -- Red: lock, Svelte
    DevIconlock = { fg = M.base_30.red },
    DevIconSvelte = { fg = M.base_30.red },
    -- White: mp3, mp4, out, ttf, woff, woff2
    DevIconmp3 = { fg = M.base_30.white },
    DevIconmp4 = { fg = M.base_30.white },
    DevIconout = { fg = M.base_30.white },
    DevIconttf = { fg = M.base_30.white },
    DevIconwoff = { fg = M.base_30.white },
    DevIconwoff2 = { fg = M.base_30.white },
    -- Teal: ts
    DevIconts = { fg = M.base_30.teal },
    -- Pink: rb
    DevIconrb = { fg = M.base_30.pink },
    -- Vibrant green: vue
    DevIconvue = { fg = M.base_30.vibrant_green },
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
