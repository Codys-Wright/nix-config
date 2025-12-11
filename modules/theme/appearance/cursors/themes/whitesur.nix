# WhiteSur Cursor Theme
# macOS Big Sur-like cursor theme
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.theme._.cursors._.themes._.whitesur =
    {
      size ? 24,
      ...
    }@args:
    { class, aspect-chain }:
    {
      description = "WhiteSur cursor theme (macOS Big Sur style)";

      homeManager = {
        home.pointerCursor = {
          name = "WhiteSur-cursors";
          package = pkgs.whitesur-cursors;
          size = size;
          gtk.enable = true;
          x11.enable = true;
        };
      };
    };
}

