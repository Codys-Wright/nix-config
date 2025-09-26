{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim;
in
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  options.${namespace}.coding.editor.nvim = with types; {
    enable = mkBoolOpt false "Enable Neovim editor";
  };

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;
                        enableManpages = true;
      # Base nvf settings - sub-modules will add their own configurations
      settings = {
        vim = {
          viAlias = false;
          vimAlias = true;

        };
      };
    };

    # Enable the editor module
    ${namespace}.coding.editor.nvim.modules = {
      editor = enabled;
      formatting = enabled;
      coding = enabled;
      ui = enabled;
      snacks = enabled;
      lazy = enabled;
    };

    # Set environment variables
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
} 
