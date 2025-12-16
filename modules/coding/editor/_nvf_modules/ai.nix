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

  # Available AI assistants in nvf:
  # - copilot (GitHub Copilot) ✓ ENABLED
  # - avante (Avante AI assistant)
  # - supermaven-nvim (Supermaven AI autocompletion)
  # - chatgpt (ChatGPT AI assistant)
  # - codecompanion (CodeCompanion AI assistant)
  #
  # Missing from LazyVim's list (would need to be added):
  # - codeium (Codeium AI autocompletion)
  # - claudecode (Claude Code AI assistant)
  # - copilot-chat (CopilotChat for chatting)
  # - copilot-native (Native Copilot LSP - Neovim 0.12+)
  # - sidekick (Sidekick for next edit suggestions)
  # - tabnine (TabNine AI autocompletion)
}
