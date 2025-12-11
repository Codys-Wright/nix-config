# Terminals meta-aspect - function that includes all terminal modules
{
  FTS,
  lib,
  ...
}:
{
  # Function that produces an aspect with all terminals
  FTS.coding._.terminals =
    {
      default ? "ghostty",
      ...
    }@args:
    {
      description = "Terminal modules - includes all terminals (ghostty, kitty, tmux, wezterm)";

      includes = [
        FTS.coding._.ghostty
        FTS.coding._.kitty
        FTS.coding._.tmux
        FTS.coding._.wezterm
      ];
    };
}
