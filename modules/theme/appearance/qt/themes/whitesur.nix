# WhiteSur Qt/KDE Theme
# macOS Big Sur-like Qt and KDE theme
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.theme._.qt._.themes._.whitesur = {
    description = "WhiteSur Qt/KDE theme (macOS Big Sur style)";

    homeManager = {
      qt = {
        enable = true;
        platformTheme.name = "gtk";  # Use GTK theme for Qt apps
        style.name = "adwaita-dark";
      };
    };

    # NixOS-level configuration for KDE Plasma
    nixos = {
      # Install WhiteSur KDE theme system-wide
      environment.systemPackages = [ pkgs.whitesur-kde ];
    };
  };
}

