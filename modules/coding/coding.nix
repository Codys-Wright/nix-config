# Coding parametric aspect
# All editors, terminals, shells, languages, and tools are included.
# Use `default` to pick the primary shell (login shell) and terminal ($TERMINAL).
#
# Usage: (fleet.coding {
#   editor   = { default = "nvf"; };
#   terminal = { default = "ghostty"; };
#   shell    = { default = "fish"; };
# })
{
  lib,
  den,
  fleet,
  __findFile,
  ...
}:
{
  fleet.coding.description = "Development tools, languages, editors, terminals, and shells";

  fleet.coding.__functor =
    _self:
    {
      editor ? { },
      terminal ? { },
      shell ? { },
      ...
    }:
    den.lib.parametric {
      includes = [
        # CLI tools
        <fleet.coding/cli>
        <fleet.coding._.tools/git>
        <fleet.coding._.tools/lazygit>
        <fleet.coding._.tools/dev-tools>

        # All editors
        <fleet.coding._.editors/nvf>
        <fleet.coding._.editors/cursor>
        <fleet.coding._.editors/zed>
        <fleet.coding._.editors/neovim>

        # All terminals
        <fleet.coding._.terminals/ghostty>
        <fleet.coding._.terminals/kitty>
        <fleet.coding._.terminals/tmux>
        <fleet.coding._.terminals/zellij>
        <fleet.coding._.terminals/wezterm>

        # All shells
        <fleet.coding._.shells/fish>
        <fleet.coding._.shells/zsh>
        <fleet.coding._.shells/nushell>
        <fleet.coding._.shells/oh-my-posh>

        # All languages
        <fleet.coding._.lang/rust>
        <fleet.coding._.lang/typescript>
        <fleet.coding._.lang/python>

        # All tools
        <fleet.coding._.tools/android>
        <fleet.coding._.tools/dioxus>
        <fleet.coding._.tools/reverse-engineering>
        <fleet.coding._.tools/opencode>
        <fleet.coding._.tools._.containers/podman>
      ]
      # Set defaults
      ++ lib.optional (shell ? default) (fleet.user._.shell { default = shell.default; })
      ++ lib.optional (terminal ? default) (fleet.coding._.user-terminal terminal.default);
    };
}
