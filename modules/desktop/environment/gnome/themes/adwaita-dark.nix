# Adwaita GNOME Theme (Dark)
# Default GNOME theme - dark variant
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.desktop._.environment._.gnome._.themes._.adwaita-dark = {
    description = "Adwaita Dark theme (default GNOME dark theme)";

    homeManager = {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
          icon-theme = "Adwaita";
        };
      };
    };
  };
}

