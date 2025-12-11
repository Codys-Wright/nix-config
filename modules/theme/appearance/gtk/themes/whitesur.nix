# WhiteSur GTK Theme
# macOS Big Sur-like GTK theme
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.theme._.gtk._.themes._.whitesur = {
    description = "WhiteSur Dark GTK theme (macOS Big Sur style)";

    homeManager = {
      gtk = {
        enable = true;
        theme = {
          name = "WhiteSur-Dark";
          package = pkgs.whitesur-gtk-theme;
        };
      };
    };
  };

  FTS.theme._.gtk._.themes._.whitesur-light = {
    description = "WhiteSur Light GTK theme (macOS Big Sur style)";

    homeManager = {
      gtk = {
        enable = true;
        theme = {
          name = "WhiteSur-Light";
          package = pkgs.whitesur-gtk-theme;
        };
      };
    };
  };
}

