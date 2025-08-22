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
  presetCfg = cfg.presets.default;
in {
  config = mkIf (cfg.preset == "default" && presetCfg.enable) (mkMerge [
    # Use nvf's standalone configuration for full control
    {
      programs.neovim = {
        enable = true;
        package = (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [
            {
              config.vim = {
                viAlias = false;
                vimAlias = true;
                # Disable default theme to avoid conflicts with our UI module
                theme = {
                  enable = false;
                };
              };
            }
          ];
        }).neovim;
      };

      # Enable the editor module
      ${namespace}.coding.editor.nvim.modules = {
        editor = enabled;
        formatting = enabled;
        coding = enabled;
        ui = enabled;
        snacks = disabled;  # Disable snacks module to avoid dashboard conflicts
      };

      # Set environment variables
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    }
  ]);
} 