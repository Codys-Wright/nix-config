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
              nav_h = { "<C-h>", "term_nav('h')", desc = "Go to Left Window", expr = true, mode = "t" };
              nav_j = { "<C-j>", "term_nav('j')", desc = "Go to Lower Window", expr = true, mode = "t" };
              nav_k = { "<C-k>", "term_nav('k')", desc = "Go to Upper Window", expr = true, mode = "t" };
              nav_l = { "<C-l>", "term_nav('l')", desc = "Go to Right Window", expr = true, mode = "t" };
            };
          };
        };
      };
    };

    # Additional keybindings for snacks
    binds.whichKey.register = {
      "<leader>." = "Toggle Scratch Buffer";
      "<leader>S" = "Select Scratch Buffer";
      "<leader>dps" = "Profiler Scratch Buffer";
    };

    # Keybindings for snacks functionality
    binds.whichKey.spec = [
      {
        mode = [ "n" ];
        "<leader>." = {
          function = "Snacks.scratch()";
          desc = "Toggle Scratch Buffer";
        };
        "<leader>S" = {
          function = "Snacks.scratch.select()";
          desc = "Select Scratch Buffer";
        };
        "<leader>dps" = {
          function = "Snacks.profiler.scratch()";
          desc = "Profiler Scratch Buffer";
        };
      }
    ];
  };
} 