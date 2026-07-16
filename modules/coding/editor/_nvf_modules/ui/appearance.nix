# UI appearance (themes runtime path, filetree, NUI, mini.icons, theme notes)
# Split from ../ui.nix — returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{ lib, ... }:
let
  # Path to custom themes directory (contains lua/themes/*.lua files)
  # This will be added to runtime path so base46 can find themes via require("themes.tokyonight_moon")
  themesDir = ../themes;
in
{
  # Add themes directory to runtime path so base46 can find custom themes
  # base46 looks for themes via require("themes.{name}") which searches runtimepath
  # This is pure/reproducible since the theme file is in the Nix store
  additionalRuntimePaths = [ themesDir ];

  # UI features
  # Disable nvim-tree in favor of snacks explorer (configured in snacks.nix)
  filetree = {
    nvimTree.enable = false;
  };

  # Add NUI (UI component library) - required by many plugins
  # NUI is available in nvf as "nui-nvim" but doesn't have a module yet
  startPlugins = [ "nui-nvim" ];

  # Mini.icons configuration (LazyVim-style)
  # Provides icons and mocks nvim-web-devicons
  mini = {
    icons = {
      enable = true;
      # LazyVim-style mini.icons configuration
      setupOpts = {
        file = {
          ".keep" = {
            glyph = "󰊢";
            hl = "MiniIconsGrey";
          };
          "devcontainer.json" = {
            glyph = "";
            hl = "MiniIconsAzure";
          };
        };
        filetype = {
          dotenv = {
            glyph = "";
            hl = "MiniIconsYellow";
          };
        };
      };
    };
  };

  # Theme configuration (TokyoNight Moon)
  # Theme configuration (TokyoNight Moon)
  # Disabled - using base46 theme instead (tokyonight_moon from chadrc.base46.theme)
  # theme = {
  #   enable = true;
  #   name = "tokyonight";
  #   style = "moon";
  #   transparent = false;
  # };
}
