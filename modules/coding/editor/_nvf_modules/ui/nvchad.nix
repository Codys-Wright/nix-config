# NvChad UI wiring (base46 cache, lzn-auto-require enable, chadrc config)
# Split from ../ui.nix — returns config.vim settings directly
{
  lib,
  nvf ? null,
  ...
}:
{
  # NvChad UI configuration (provides cheatsheet, statusline, tabufline, etc.)
  # The plugin requires nvconfig and base46 to be available
  # Base46 setup - must run very early, before plugins load
  # Use luaConfigRC with entryBefore to run before pluginConfigs
  luaConfigRC.nvchad-base46-cache =
    if nvf != null then
      nvf.lib.nvim.dag.entryBefore [ "pluginConfigs" ] ''
        -- Initialize base46 cache path (required by nvchad-ui and base46)
        -- This must be set before base46 loads (before lazy.setup)
        vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

      ''
    else
      ''
        -- Initialize base46 cache path (required by nvchad-ui and base46)
        -- This must be set before base46 loads
        vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46_cache/"

      '';

  # Theme file is now written in nvchad-base46-cache (above) to ensure it exists before plugins load

  # Base46 initialization is now handled in base46's setup function (in nvf.nix)
  # This loads the theme immediately when base46 loads, before UI renders
  # No separate initialization needed here

  # Enable lzn-auto-require as late as possible (after all plugins are configured)
  # This allows lazy-loading of optional modules like nvchad.cheatsheet.grid
  luaConfigRC.lzn-auto-require-enable =
    if nvf != null then
      nvf.lib.nvim.dag.entryAfter [ "mappings" ] ''
        -- Enable lzn-auto-require as late as possible
        -- This allows lazy-loading of optional modules from opt plugins
        if package.loaded["lzn-auto-require"] then
          require("lzn-auto-require").enable()
        end
        -- Ensure nvchad.themes module is available (it's lazy-loaded via lzn-auto-require)
        -- Pre-load volt since themes module requires it
        if package.loaded["volt"] and package.loaded["nvchad-ui"] then
          -- Pre-require nvchad.themes to make it available
          pcall(require, "nvchad.themes")
        end
      ''
    else
      ''
        -- Enable lzn-auto-require as late as possible
        vim.defer_fn(function()
          if package.loaded["lzn-auto-require"] then
            require("lzn-auto-require").enable()
          end
          -- Ensure nvchad.themes module is available
          if package.loaded["volt"] and package.loaded["nvchad-ui"] then
            pcall(require, "nvchad.themes")
          end
          -- Ensure nvchad.blink module is available for blink.cmp
          if package.loaded["nvchad-ui"] then
            pcall(require, "nvchad.blink")
          end
        end, 100)
      '';

  # NvChad UI configuration - must run before base46 loads
  # Use entryBefore to ensure chadrc is configured before base46's setup function runs
  luaConfigRC.nvchad-ui-config =
    if nvf != null then
      nvf.lib.nvim.dag.entryBefore [ "pluginConfigs" ] ''
        -- Create chadrc configuration for nvchad-ui
        -- This provides the configuration that nvchad-ui expects (similar to chadrc.lua)
        -- Structure matches nvconfig.lua from nvchad-ui
        local chadrc = {
          base46 = {
            theme = "tokyonight_moon", -- Custom tokyonight_moon theme from lua/themes/
            hl_add = {},
            hl_override = {},
            integrations = {},
            changed_themes = {},
            transparency = false,
            theme_toggle = { "tokyonight_moon", "onedark" }, -- Themes available for toggle
          },
          ui = {
            cmp = {
              icons_left = false, -- Automatically set by atom/atom_colored style
              style = "atom_colored", -- atom/atom_colored: icons left, label middle, kind (muted) right
              -- style options: default/flat_light/flat_dark/atom/atom_colored
              abbr_maxwidth = 60,
              format_colors = { lsp = true, icon = "󱓻" },
            },
            telescope = { style = "borderless" },
            statusline = {
              enabled = true, -- Enable NvChad statusline
              theme = "default",
              separator_style = "default",
              order = nil,
              modules = nil,
            },
            tabufline = {
              enabled = true, -- Enable NvChad tabufline
              lazyload = true,
              order = { "treeOffset", "buffers", "tabs", "btns" },
              modules = nil,
              bufwidth = 21,
            },
          },
          nvdash = {
            load_on_startup = false,
            header = {
              "                      ",
              "  ▄▄         ▄ ▄▄▄▄▄▄▄",
              "▄▀███▄     ▄██ █████▀ ",
              "██▄▀███▄   ███        ",
              "███  ▀███▄ ███        ",
              "███    ▀██ ███        ",
              "███      ▀ ███        ",
              "▀██ █████▄▀█▀▄██████▄ ",
              "  ▀ ▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀",
              "                      ",
              "   Powered By  eovim ",
              "                      ",
            },
            buttons = {
              { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
              { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
              { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
              { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
              { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
            },
          },
          term = {
            startinsert = true,
            base46_colors = true,
            winopts = { number = false, relativenumber = false },
            sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
            float = {
              relative = "editor",
              row = 0.3,
              col = 0.25,
              width = 0.5,
              height = 0.4,
              border = "single",
            },
          },
          lsp = { signature = true },
          cheatsheet = {
            theme = "grid", -- grid or simple
            excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" },
          },
          mason = { pkgs = {}, skip = {} },
          colorify = {
            enabled = true,
            mode = "virtual",
            virt_text = "󱓻 ",
            highlight = { hex = true, lspvars = true },
          },
        }

        -- Make chadrc available (nvchad-ui expects it via require("chadrc"))
        package.preload["chadrc"] = function()
          return chadrc
        end

        -- Also make nvconfig available (some parts of nvchad-ui use this)
        package.preload["nvconfig"] = function()
          return chadrc
        end

        -- Set as globals for compatibility
        _G.chadrc = chadrc
        _G.nvconfig = chadrc
      ''
    else
      ''
        -- Create chadrc configuration for nvchad-ui
        local chadrc = {
          base46 = {
            theme = "tokyonight_moon",
            hl_add = {},
            hl_override = {},
            integrations = {},
            changed_themes = {},
            transparency = false,
            theme_toggle = { "tokyonight_moon", "onedark" },
          },
          ui = {
            cmp = { style = "atom_colored" },
            telescope = { style = "borderless" },
            statusline = { enabled = true, theme = "default" },
            tabufline = { enabled = true, lazyload = true },
          },
          lsp = { signature = true },
          cheatsheet = { theme = "grid" },
          mason = { pkgs = {}, skip = {} },
          colorify = { enabled = true, mode = "virtual" },
        }
        package.preload["chadrc"] = function() return chadrc end
        package.preload["nvconfig"] = function() return chadrc end
        _G.chadrc = chadrc
        _G.nvconfig = chadrc
      '';
}
