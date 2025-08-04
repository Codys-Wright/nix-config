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
      binds.whichKey.setupOpts = {
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
      binds.whichKey.register = {
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
        "gx" = "Open with system app";
      };
      
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


    # Diagnostics viewer with trouble.nvim
    lsp.trouble = {
      enable = true;
      mappings = {
        workspaceDiagnostics = "<leader>xx";
        documentDiagnostics = "<leader>xX";
        symbols = "<leader>cs";
        lspReferences = "<leader>cS";
        locList = "<leader>xL";
        quickfix = "<leader>xQ";
      };
      setupOpts = {
        modes = {
          lsp = {
            win = { position = "right"; };
          };
        };
      };
    };

    # Todo comments highlighting and search
    notes.todo-comments = {
      enable = true;
      mappings = {
        telescope = "<leader>st";
        trouble = "<leader>xt";
        quickFix = "<leader>tdq";
      };
      setupOpts = {
        search.command = "rg";
        search.args = [
          "--color=never"
          "--no-heading"
          "--with-filename"
          "--line-number"
          "--column"
        ];
        search.pattern = "\\b(KEYWORDS)(\\([^\\)]*\\))?:";
        highlight.pattern = ".*<(KEYWORDS)(\\([^\\)]*\\))?:";
        # Additional mappings not exposed by nvf
        keys = [
          {
            "]t" = {
              function = "require('todo-comments').jump_next()";
              desc = "Next Todo Comment";
            };
            "[t" = {
              function = "require('todo-comments').jump_prev()";
              desc = "Previous Todo Comment";
            };
            "<leader>xT" = {
              cmd = "Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}";
              desc = "Todo/Fix/Fixme (Trouble)";
            };
            "<leader>sT" = {
              cmd = "TodoTelescope keywords=TODO,FIX,FIXME";
              desc = "Todo/Fix/Fixme";
            };
          }
        ];
      };
    };

    # Treesitter for syntax highlighting
    treesitter.enable = true;
      
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
        # toggleSigns = "<leader>uG";  # TODO: Not available in nvf gitsigns module
      };
      setupOpts = {
        signs = {
          add = { text = "▎"; };
          change = { text = "▎"; };
          delete = { text = ""; };
          topdelete = { text = ""; };
          changedelete = { text = "▎"; };
          untracked = { text = "▎"; };
        };
        signs_staged = {
          add = { text = "▎"; };
          change = { text = "▎"; };
          delete = { text = ""; };
          topdelete = { text = ""; };
          changedelete = { text = "▎"; };
        };
      };
    };
    };
  };
} 