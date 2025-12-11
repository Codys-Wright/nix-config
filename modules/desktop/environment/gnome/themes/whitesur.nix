# WhiteSur GNOME Theme
# macOS Big Sur-like theme for GNOME (uses GTK theme from theme modules)
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.desktop._.environment._.gnome._.themes._.whitesur = {
    description = "WhiteSur GNOME theme (macOS Big Sur style)";

    # Note: GTK and icon themes should be configured via FTS.theme modules
    # This theme just configures GNOME-specific settings
    # includes = [
    #   (FTS.theme._.gtk { theme = "whitesur"; })
    #   (FTS.theme._.icons { theme = "whitesur-dark"; })
    # ];

    homeManager = {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          # GTK theme is set by FTS.theme._.gtk
          # icon-theme is set by FTS.theme._.icons
        };
        
        # GNOME Shell theme configuration
        "org/gnome/shell" = {
          # WhiteSur shell theme would go here if available
        };
      };
    };

    nixos = {
      # Install GNOME Shell extensions that complement WhiteSur
      environment.systemPackages = with pkgs; [
        gnomeExtensions.user-themes  # Allow shell theme customization
      ];
    };
  };
}

