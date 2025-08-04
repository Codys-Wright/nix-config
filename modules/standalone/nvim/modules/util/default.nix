{
  config.vim = {
    # Snacks.nvim - Collection of QoL plugins
    utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        bigfile = { enabled = true; };
        dashboard = { enabled = true; };
        explorer = { enabled = true; };
        indent = { enabled = true; };
        input = { enabled = true; };
        notifier = {
          enabled = true;
          timeout = 3000;
        };
        picker = { enabled = true; };
        quickfile = { enabled = true; };
        scope = { enabled = true; };
        scroll = { enabled = true; };
        statuscolumn = { enabled = true; };
        words = { enabled = true; };
        styles = {
          notification = {
            # wo = { wrap = true } # Wrap notifications
          };
        };
        terminal = {
          win = {
            keys = {
              nav_h = [ "<C-h>" "term_nav('h')" "Go to Left Window" true "t" ];
              nav_j = [ "<C-j>" "term_nav('j')" "Go to Lower Window" true "t" ];
              nav_k = [ "<C-k>" "term_nav('k')" "Go to Upper Window" true "t" ];
              nav_l = [ "<C-l>" "term_nav('l')" "Go to Right Window" true "t" ];
            };
          };
        };
      };
    };

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
} 