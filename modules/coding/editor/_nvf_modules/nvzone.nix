# Nvzone plugins configuration - All nvzone plugins in one module
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Floaterm plugin configuration
  extraPlugins = {
    floaterm = {
      # Package is passed from nvf.nix (from npins)
      # package will be set in nvf.nix
      setup = ''
        require("floaterm").setup({
          border = false,
          size = { h = 60, w = 70 },
          -- Default sets of terminals you'd like to open
          terminals = {
            { name = "Terminal" },
            -- You can add more terminals here
            -- { name = "Terminal", cmd = "neofetch" },
          },
          -- Mappings for sidebar and terminal
          mappings = {
            sidebar = function(buf)
              -- Sidebar mappings (when sidebar is open)
              -- a -> add new terminal
              -- e -> edit terminal name
              -- Pressing any number switches to that terminal
            end,
            term = function(buf)
              -- Terminal mappings (when in terminal buffer)
              -- Note: Ctrl+h for sidebar may need to be configured differently
              -- The API function toggle_sidebar() doesn't exist, so we'll skip it for now
              -- Ctrl+j -> Cycle to previous terminal
              vim.keymap.set({ "n", "t" }, "<C-j>", function()
                require("floaterm.api").cycle_term_bufs("prev")
              end, { buffer = buf, desc = "Previous Terminal" })
              -- Ctrl+k -> Cycle to next terminal
              vim.keymap.set({ "n", "t" }, "<C-k>", function()
                require("floaterm.api").cycle_term_bufs("next")
              end, { buffer = buf, desc = "Next Terminal" })
            end,
          },
        })
      '';
    };

    # Volt is a dependency of floaterm
    volt = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      # volt doesn't need setup, just needs to be loaded
    };

    # Typr plugin
    typr = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      setup = ''
        require("typr").setup({
          -- Add typr configuration here
          -- Check typr documentation for available options
        })
      '';
    };

    # Timerly plugin
    timerly = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      setup = ''
        require("timerly").setup({
          -- Add timerly configuration here
          -- Check timerly documentation for available options
        })
      '';
    };

    # Showkeys plugin - Eye-candy keys screencaster for Neovim
    showkeys = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      setup = ''
        require("showkeys").setup({
          timeout = 1,  -- Timeout in seconds before hiding keys
          maxkeys = 3,  -- Maximum number of keys to show
          -- More options can be added here as needed
        })
      '';
    };
  };

  # Enable showkeys by default on startup
  luaConfigRC.showkeys-autostart = ''
    -- Enable showkeys by default when Neovim starts
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("ShowKeysAutoStart", { clear = true }),
      pattern = "*",
      callback = function()
        vim.cmd("ShowkeysToggle")
      end,
    })
  '';

  # Floaterm keymaps (LazyVim-style)
  # Note: Terminal-specific mappings (Ctrl+h/j/k) are set up in the setup config
  # above via the mappings.term function, as they need to be buffer-local
  # Using <leader>tf (terminal floaterm) to avoid conflict with snacks terminal
  # which uses <leader>ft and <leader>fT
  # nvzone/floaterm uses commands: FloatermToggle, FloatermNew, etc.
  keymaps = [
    {
      key = "<leader>tf";
      mode = ["n" "t"];
      action = "<cmd>FloatermToggle<cr>";
      desc = "Toggle Floating Terminal (Floaterm)";
    }
    {
      key = "<leader>tn";
      mode = ["n" "t"];
      action = "<cmd>FloatermNew<cr>";
      desc = "New Floating Terminal (Floaterm)";
    }
    {
      key = "<C-p>";
      mode = ["n" "t"];
      action = "<cmd>FloatermToggle<cr>";
      desc = "Toggle Floating Terminal (Floaterm)";
    }
    # Typr keymaps - Git/Group G
    {
      key = "<leader>Gt";
      mode = "n";
      action = "<cmd>Typr<cr>";
      desc = "Typr";
    }
    {
      key = "<leader>Gts";
      mode = "n";
      action = "<cmd>TyprStats<cr>";
      desc = "Typr Stats";
    }
    # Timerly keymap - Git/Group G
    {
      key = "<leader>Gtl";
      mode = "n";
      action = "<cmd>TimerlyToggle<cr>";
      desc = "Toggle Timerly";
    }
    # Showkeys keymap - UI group
    {
      key = "<leader>uk";
      mode = "n";
      action = "<cmd>ShowkeysToggle<cr>";
      desc = "Toggle Showkeys";
    }
  ];

  # Note: which-key automatically discovers keymaps with desc attributes.
  # We only need manual registrations for category prefixes (handled in which-key.nix).
}
