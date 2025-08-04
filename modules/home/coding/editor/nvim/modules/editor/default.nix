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
      # Vim options
      options = {
        # Enable shada for yanky.nvim
        shada = "'100,<50,s10,h";
      };

      # Core editing features
      mini = {
        basics.enable = true;
        comment.enable = true;
        completion.enable = true;
        cursorword.enable = true;
        diff.enable = true;
        doc.enable = true;
        files = {
          enable = true;
          setupOpts = {
            windows = {
              preview = true;
              width_focus = 30;
              width_preview = 30;
            };
            options = {
              # Whether to use for editing directories
              # Disabled by default in LazyVim because neo-tree is used for that
              use_as_default_explorer = false;
            };
          };
        };

        jump.enable = true;
        map.enable = true;
        misc.enable = true;
        move.enable = true;
        notify.enable = true;
        operators.enable = true;
        pairs.enable = true;
        pick.enable = true;
        sessions.enable = true;
        splitjoin.enable = true;
        # starter.enable = true; # Disabled - using snacks dashboard instead
        surround.enable = true;
        test.enable = true;
        visits.enable = true;
      };

      # Keybindings with which-key
      binds.whichKey = {
        enable = true;
        register = {
          "<leader><tab>" = "tabs";
          "<leader>c" = "code";
          "<leader>d" = "debug";
          "<leader>dp" = "profiler";
          "<leader>f" = "file/find";
          "<leader>g" = "git";
          "<leader>gh" = "hunks";
          "<leader>q" = "quit/session";
          "<leader>s" = "search";
          "<leader>u" = "ui";
          "<leader>x" = "diagnostics/quickfix";
          "[" = "prev";
          "]" = "next";
          "g" = "goto";
          "gs" = "surround";
          "z" = "fold";
          "<leader>b" = "buffer";
          "<leader>w" = "windows";
          "gx" = "Open with system app";
        };
        setupOpts = {
          preset = "helix";
          notify = true;
          replace = {
            "<cr>" = "RETURN";
            "<leader>" = "SPACE";
            "<space>" = "SPACE";
            "<tab>" = "TAB";
          };
          win.border = "rounded";
        };
      };

      # Git integration with gitsigns
      git.gitsigns = {
        enable = true;
        mappings = {
          nextHunk = "]h";
          previousHunk = "[h";
          stageHunk = "<leader>ghs";
          resetHunk = "<leader>ghr";
          stageBuffer = "<leader>ghS";
          undoStageHunk = "<leader>ghu";
          resetBuffer = "<leader>ghR";
          previewHunk = "<leader>ghp";
          blameLine = "<leader>ghb";
          diffThis = "<leader>ghd";
          diffProject = "<leader>ghD";
        };
      };
    };
  };
}
