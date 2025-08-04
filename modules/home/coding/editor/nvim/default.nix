{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim;
in
{
  options.${namespace}.coding.editor.nvim = with types; {
    enable = mkBoolOpt false "Enable Neovim editor";
    preset = mkOption {
      type = types.enum [ "default" "lazy" "minimal" ];
      default = "default";
      description = "Neovim preset to use";
    };
  };

  config = mkIf cfg.enable {
    # Import the nvf home-manager module
    imports = [ inputs.nvf.homeManagerModules.default ];

    # Configure nvf with the selected preset
    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          # Basic settings
          viAlias = false;
          vimAlias = true;
          
          # Import the selected preset
          imports = [ ./presets/${cfg.preset} ];
        };
      };
    };
  };
} 