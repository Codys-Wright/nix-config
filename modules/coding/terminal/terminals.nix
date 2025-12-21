# Terminals facet - All terminal emulators
{FTS, ...}: {
  FTS.coding._.terminals = {
    description = "All terminal emulators - ghostty, kitty, tmux, wezterm";

    includes = [
      FTS.coding._.terminals._.ghostty
      FTS.coding._.terminals._.kitty
      FTS.coding._.terminals._.tmux
      FTS.coding._.terminals._.zellij
      FTS.coding._.terminals._.wezterm
    ];
  };
}
