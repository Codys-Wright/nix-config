{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.${namespace}.coding.editor.nvim;
in {
  options.${namespace}.coding.editor.nvim = {
    # Preset selection
    preset = mkOption {
      description = "Neovim preset to use";
      type = types.enum ["default" "lazyvim" "minimal"];
      default = "default";
      example = "lazyvim";
    };
    
    # Preset-specific options
    presets = {
      default = {
        enable = mkOption {
          description = "Enable default preset";
          type = types.bool;
          default = true;
        };
      };
      
      lazyvim = {
        enable = mkOption {
          description = "Enable LazyVim-style preset";
          type = types.bool;
          default = false;
        };
        # LazyVim-specific options can go here
        options = {
          colorscheme = mkOption {
            description = "Default colorscheme for LazyVim preset";
            type = types.str;
            default = "catppuccin";
          };
        };
      };
      
      minimal = {
        enable = mkOption {
          description = "Enable minimal preset";
          type = types.bool;
          default = false;
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Preset configurations are automatically available via Snowfall Lib
  ]);
} 