# Adwaita GNOME Theme (Light)
# Default GNOME theme - light variant
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.desktop._.environment._.gnome._.themes._.adwaita = {
    description = "Adwaita Light theme (default GNOME theme)";

    homeManager = {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-light";
          gtk-theme = "Adwaita";
          icon-theme = "Adwaita";
        };
      };
    };
  };
}

