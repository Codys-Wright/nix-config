# AI assistants and AI-powered features
# Based on LazyVim's AI extras
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{
  lib,
  nvf ? null,
  ...
}: {
  # Enable GitHub Copilot AI autocompletion
  # Configured to work with blink.cmp (similar to LazyVim)
  assistant = {
    copilot = {
      enable = false; # Disabled - removed AI integration
      # Disable nvim-cmp integration since we're using blink.cmp
      # blink.cmp integration is configured separately in lsp.nix
      cmp.enable = false;
      # Configure copilot to work with blink.cmp
      # Disable inline suggestions since we're using cmp
      setupOpts = {
        suggestion = {
          enabled = false; # Disable inline suggestions, use blink.cmp instead
          auto_trigger = true;
          hide_during_completion = true; # Hide during blink.cmp completion
          keymap = {
            accept = false; # Handled by blink.cmp
            next = "<M-]>";
            prev = "<M-[>";
          };
        };
        panel = {
          enabled = false; # Disable panel, use blink.cmp
        };
        filetypes = {
          markdown = true;
          help = true;
        };
      };
    };
  };

  # Note: blink.cmp integration for copilot is configured in lsp.nix
  # The copilot source is added to blink.cmp's sources.default and sources.providers

  # Sidekick plugin configuration
  # Sidekick provides next edit suggestions and CLI integration
  extraPlugins = {
    sidekick = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      setup = ''
        require("sidekick").setup({
          cli = {
            mux = {
              backend = "zellij",
              enabled = true,
            },
          },
        })
      '';
    };
  };

  # Sidekick keymaps
  keymaps = [
    {
      key = "<tab>";
      mode = ["n" "i"];
      action = "function() if not require('sidekick').nes_jump_or_apply() then return '<Tab>' end end";
      lua = true;
      expr = true;
      desc = "Goto/Apply Next Edit Suggestion";
    }
    {
      key = "<c-.>";
      mode = ["n" "t" "i" "x"];
      action = "function() require('sidekick.cli').toggle() end";
      lua = true;
      desc = "Sidekick Toggle";
    }
    {
      key = "<leader>aa";
      mode = "n";
      action = "function() require('sidekick.cli').toggle() end";
      lua = true;
      desc = "Sidekick Toggle CLI";
    }
    {
      key = "<leader>as";
      mode = "n";
      action = "function() require('sidekick.cli').select() end";
      lua = true;
      desc = "Select CLI";
    }
    {
      key = "<leader>ad";
      mode = "n";
      action = "function() require('sidekick.cli').close() end";
      lua = true;
      desc = "Detach a CLI Session";
    }
    {
      key = "<leader>at";
      mode = ["x" "n"];
      action = "function() require('sidekick.cli').send({ msg = '{this}' }) end";
      lua = true;
      desc = "Send This";
    }
    {
      key = "<leader>af";
      mode = "n";
      action = "function() require('sidekick.cli').send({ msg = '{file}' }) end";
      lua = true;
      desc = "Send File";
    }
    {
      key = "<leader>av";
      mode = "x";
      action = "function() require('sidekick.cli').send({ msg = '{selection}' }) end";
      lua = true;
      desc = "Send Visual Selection";
    }
    {
      key = "<leader>ap";
      mode = ["n" "x"];
      action = "function() require('sidekick.cli').prompt() end";
      lua = true;
      desc = "Sidekick Select Prompt";
    }
    {
      key = "<leader>ac";
      mode = "n";
      action = "function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end";
      lua = true;
      desc = "Sidekick Toggle Claude";
    }
  ];

  # Available AI assistants in nvf:
  # - copilot (GitHub Copilot) ✓ ENABLED
  # - avante (Avante AI assistant)
  # - supermaven-nvim (Supermaven AI autocompletion)
  # - chatgpt (ChatGPT AI assistant)
  # - codecompanion (CodeCompanion AI assistant)
  # - sidekick (Sidekick for next edit suggestions) ✓ ENABLED
  #
  # Missing from LazyVim's list (would need to be added):
  # - codeium (Codeium AI autocompletion)
  # - claudecode (Claude Code AI assistant)
  # - copilot-chat (CopilotChat for chatting)
  # - copilot-native (Native Copilot LSP - Neovim 0.12+)
  # - tabnine (TabNine AI autocompletion)
}
