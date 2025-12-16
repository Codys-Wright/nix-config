# Which-key configuration with LazyVim-style categories and UI
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Enable which-key
  binds.whichKey.enable = true;

  # LazyVim-style which-key configuration
  # Note: nvf's which-key module only exposes limited options via setupOpts
  # We use helix preset and extend with luaConfigRC for full LazyVim styling
  binds.whichKey.setupOpts = {
    # Use helix preset (LazyVim's default)
    preset = "helix";
  };

  # Additional LazyVim-style UI configuration via luaConfigRC
  # luaConfigRC runs after pluginConfigs, so we can safely extend which-key here
  # Re-setup with full LazyVim-style configuration (which-key allows multiple setup calls)
  luaConfigRC.which-key-ui = ''
    -- LazyVim-style which-key UI configuration
    -- Re-setup with full configuration (last setup call takes precedence)
    vim.defer_fn(function()
      local wk = require("which-key")
      if wk then
        wk.setup({
          preset = "helix",
          win = {
            position = "right",
            margin = {1, 0, 1, 0}, -- top, right, bottom, left
            padding = {2, 2}, -- vertical, horizontal
            winblend = 0, -- transparency
          },
          layout = {
            height = {min = 4, max = 25},
            width = {min = 20, max = 50},
            spacing = 3,
            align = "left",
          },
          triggers = "auto",
          show_help = true,
          key_labels = {
            ["<space>"] = "SPC",
            ["<cr>"] = "RET",
            ["<tab>"] = "TAB",
          },
        })
      end
    end, 0)
  '';

  # Register category prefixes (LazyVim-style)
  # Note: These are base category labels. Individual modules will add their specific keybinds.
  # We only register prefixes that don't conflict with specific keybinds defined in other modules.
  binds.whichKey.register = {
    # Main category prefixes
    "<leader>a" = "+AI";
    "<leader>c" = "+Coding";
    "<leader>d" = "+Debug";
    "<leader>f" = "+Find/File";
    "<leader>g" = "+Git";
    "<leader>h" = "+Harpoon";
    "<leader>l" = "+Language/LSP";
    "<leader>s" = "+Search";
    "<leader>t" = "+Test";
    "<leader>u" = "+UI";
    "<leader>w" = "+Workspace";
    "<leader>x" = "+Diagnostics/Trouble";
    # Note: <leader>e is handled by ui.nix for Explorer
  };

  # Add manual trigger for which-key (press <leader>? to show which-key, like LazyVim)
  keymaps = [
    {
      key = "<leader>?";
      mode = "n";
      action = "function() require('which-key').show({ global = false }) end";
      lua = true;
      desc = "Buffer Keymaps (which-key)";
    }
    {
      key = "<leader>wk";
      mode = "n";
      action = "function() require('which-key').show() end";
      lua = true;
      desc = "Which Key (global)";
    }
  ];
}
