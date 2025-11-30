# Terminals meta-aspect - includes all terminal modules
{
  FTS, ... }:
{
  FTS.terminals = {
    description = "All terminal modules - includes ghostty, kitty, tmux, and wezterm";

    includes = [
      FTS.ghostty
      FTS.kitty
      FTS.tmux
      FTS.wezterm
    ];
  };
}

