{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.util;
in
{
  options.${namespace}.coding.editor.nvim.modules.util = with types; {
    enable = mkBoolOpt false "Enable nvim utility modules";
  };

  config = mkIf cfg.enable {
    # Configure nvf utility settings
    programs.nvf.settings.vim = {
      utility.yanky-nvim.enable = true;

      # Mini.sessions for session management
      mini.sessions = {
        enable = true;
        setupOpts = {
          # Custom keybindings for session management
          keys = [
            {
              "<leader>qs" = {
                function = "require('mini.sessions').read()";
                desc = "Restore Session";
              };
              "<leader>qS" = {
                function = "require('mini.sessions').select()";
                desc = "Select Session";
              };
              "<leader>ql" = {
                function = "require('mini.sessions').read({ last = true })";
                desc = "Restore Last Session";
              };
              "<leader>qd" = {
                function = "require('mini.sessions').delete()";
                desc = "Delete Current Session";
              };
            }
          ];
        };
      };

      # Additional keybindings for sessions
      binds.whichKey.register = {
        "<leader>qs" = "Restore Session";
        "<leader>qS" = "Select Session";
        "<leader>ql" = "Restore Last Session";
        "<leader>qd" = "Delete Current Session";
      };
    };
  };
} 