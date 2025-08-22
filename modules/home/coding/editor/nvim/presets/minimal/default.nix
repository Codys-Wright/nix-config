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
  presetCfg = cfg.presets.minimal;
in {
  config = mkIf (cfg.preset == "minimal" && presetCfg.enable) (mkMerge [
    # Minimal configuration using nvf
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
                
                # Minimal theme
                theme = {
                  enable = true;
                  name = "default";
                };
                
                # Minimal plugins
                startPlugins = [
                  "nvim-treesitter"
                ];
                
                # Basic keybindings
                keymaps = [
                  {
                    key = "<leader>w";
                    action = ":w<CR>";
                    mode = ["n"];
                    desc = "Save";
                  }
                  {
                    key = "<leader>q";
                    action = ":q<CR>";
                    mode = ["n"];
                    desc = "Quit";
                  }
                ];
                
                # Basic options
                options = {
                  number = true;
                  mouse = "a";
                  ignorecase = true;
                  smartcase = true;
                  tabstop = 2;
                  shiftwidth = 2;
                  expandtab = true;
                };
              };
            }
          ];
        }).neovim;
      };

      # Set environment variables
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    }
  ]);
} 