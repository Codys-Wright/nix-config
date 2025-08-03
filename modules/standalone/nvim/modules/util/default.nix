{
  config.vim = {
    # Snacks.nvim - Collection of QoL plugins
    utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        bigfile = { enabled = true; };
        quickfile = { enabled = true; };
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

    # Additional keybindings for snacks and sessions
    binds.whichKey.register = {
      "<leader>." = "Toggle Scratch Buffer";
      "<leader>S" = "Select Scratch Buffer";
      "<leader>dps" = "Profiler Scratch Buffer";
      "<leader>qs" = "Restore Session";
      "<leader>qS" = "Select Session";
      "<leader>ql" = "Restore Last Session";
      "<leader>qd" = "Delete Current Session";
    };
  };
} 