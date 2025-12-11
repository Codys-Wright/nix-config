# WhiteSur KDE Theme
# macOS Big Sur-like theme for KDE Plasma
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.desktop._.environment._.kde._.themes._.whitesur = {
    description = "WhiteSur KDE theme (macOS Big Sur style)";

    nixos = {
      # Install WhiteSur KDE theme system-wide
      environment.systemPackages = [ 
        pkgs.whitesur-kde 
      ];
    };

    homeManager = { pkgs, ... }: {
      # User-level KDE theme configuration
      # Note: Actual theme application would be done through KDE's settings
      # This just ensures the theme package is available
      home.packages = [ 
        pkgs.whitesur-kde 
      ];
    };
  };
}

