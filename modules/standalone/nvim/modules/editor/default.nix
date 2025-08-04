{
  config.vim = {
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

    # Enhanced navigation with flash.nvim
    utility.motion.flash-nvim = {
      enable = true;
      mappings = {
        jump = "s";
        treesitter = "S";
        remote = "r";
        treesitter_search = "R";
        toggle = "<c-s>";
      };
    };

    navigation.harpoon.enable = true;

    # Mini.files keybindings
    binds.whichKey.register = {
      "<leader>fm" = "Open mini.files (Directory of Current File)";
      "<leader>fM" = "Open mini.files (cwd)";
    };
    
  };
} 