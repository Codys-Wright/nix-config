# Snacks.nvim git-related plugins configuration
# Returns config.vim settings directly
# Takes lib as parameter for consistency
{ lib, ... }:
{
  # Configure git-related plugins
  utility.snacks-nvim.setupOpts = {
    # GitHub CLI integration
    gh = {
      # Keymaps for GitHub buffers
      keys = lib.generators.mkLuaInline ''
        {
          select = { "<cr>", "gh_actions", desc = "Select Action" },
          edit = { "i", "gh_edit", desc = "Edit" },
          comment = { "a", "gh_comment", desc = "Add Comment" },
          close = { "c", "gh_close", desc = "Close" },
          reopen = { "o", "gh_reopen", desc = "Reopen" },
        }
      '';
      diff = {
        min = 4; # minimum number of lines changed to show diff
        wrap = 80; # wrap diff lines at this length
      };
      scratch = {
        height = 15; # height of scratch window
      };
      icons = {
        logo = "󰊤 ";
        user = "󰊽 ";
        checkmark = "󰐮 ";
        crossmark = "󰩶 ";
        block = "■";
        file = "󰒥 ";
        checks = {
          pending = "󰐺 ";
          success = "󰐮 ";
          failure = "󰑧";
          skipped = "󰪽 ";
        };
        issue = {
          open = "󰐛 ";
          completed = "󰐝 ";
          other = "󰪽 ";
        };
        pr = {
          open = "󰩤 ";
          closed = "󰯚 ";
          merged = "󰐙 ";
          draft = "󰯛 ";
          other = "󰯚 ";
        };
        review = {
          approved = "󰐮 ";
          changes_requested = "󰭃 ";
          commented = "󰑁 ";
          dismissed = "󰁱 ";
          pending = "󰐺 ";
        };
        merge_status = {
          clean = "󰐮 ";
          dirty = "󰩶 ";
          blocked = "󰪽 ";
          unstable = "󰁱 ";
        };
        reactions = {
          thumbs_up = "👍";
          thumbs_down = "👎";
          eyes = "👀";
          confused = "😕";
          heart = "❤️";
          hooray = "🎉";
          laugh = "😄";
          rocket = "🚀";
        };
      };
    };

    # LazyGit: Open LazyGit in a float, auto-configure colorscheme and integration
    lazygit = {
      # automatically configure lazygit to use the current colorscheme
      # and integrate edit with the current neovim instance
      configure = true;
      # extra configuration for lazygit that will be merged with the default
      config = {
        os = {
          editPreset = "nvim-remote";
        };
        gui = {
          # set to an empty string "" to disable icons
          nerdFontsVersion = "3";
        };
      };
      theme_path = lib.generators.mkLuaInline "vim.fs.normalize(vim.fn.stdpath('cache') .. '/lazygit-theme.yml')";
    };

    # GitBrowse: Open the repo of the active file in the browser (e.g., GitHub)
    gitbrowse = {
      notify = true; # show notification on open
      # what to open. not all remotes support all types
      what = "commit";
      commit = null;
      branch = null;
      line_start = null;
      line_end = null;
    };
  };
}
