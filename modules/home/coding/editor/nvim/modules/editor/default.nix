{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.editor;
in
{
  options.${namespace}.coding.editor.nvim.modules.editor = with types; {
    enable = mkBoolOpt false "Enable nvim editor modules";
  };

  config = mkIf cfg.enable {
    # Configure nvf editor settings
    programs.nvf.settings.vim = {
      # Enable which-key for keybinding help
      binds.whichKey.enable = true;
      
      # Enable telescope for fuzzy finding
      telescope.enable = true;
      
      # Enable flash-nvim for enhanced navigation
      utility.motion.flash-nvim.enable = true;
      utility.motion.flash-nvim.mappings = {
        jump = "s";
        remote = "r";
        toggle = "<c-s>";
        treesitter = "S";
        treesitter_search = "R";
      };
    };
  };
} 