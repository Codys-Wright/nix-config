# Breeze KDE Theme
# Default KDE Plasma theme
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.desktop._.environment._.kde._.themes._.breeze = {
    description = "Breeze KDE theme (default KDE theme)";

    nixos = {
      # Breeze is included by default with KDE Plasma
      # No additional packages needed
    };

    homeManager = {
      # Breeze configuration if needed
    };
  };
}

