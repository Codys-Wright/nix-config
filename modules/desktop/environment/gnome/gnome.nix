# GNOME Desktop Environment
# Provides NixOS configuration for GNOME
# Note: Display manager should be configured separately (e.g., FTS.gdm)
{
  den,
  lib,
  FTS,
  ...
}:
{
  # Base GNOME desktop environment
  FTS.gnome = {
    description = "GNOME desktop environment";

    nixos = {
      # Enable GNOME desktop manager
      services.desktopManager.gnome.enable = true;

      # Enable sysprof service for profiling
      services.sysprof.enable = true;

      # Enable sensor support for automatic screen rotation
      hardware.sensor.iio.enable = true;

      # Qt integration for better GNOME look
      qt = {
        enable = true;
        platformTheme = "gnome";
        style = "adwaita-dark";
      };
      
      # Don't set SSH askPassword (override default from gnome module)
      programs.ssh.askPassword = lib.mkForce "";
    };
  };

  # GNOME with popular extensions
  # Usage: FTS.gnome-desktop.with-extensions
  FTS.gnome.with-extensions = {
    description = "GNOME desktop with popular extensions enabled";

    includes = [ FTS.gnome ];

    homeManager = { pkgs, lib, ... }: {
      # Enable dconf for GNOME configuration
      dconf.enable = true;

      # Install popular GNOME extensions
      home.packages = with pkgs; [
        gnomeExtensions.blur-my-shell # Blur effect for shell
        gnomeExtensions.just-perfection # Extensive shell customization
        gnomeExtensions.arc-menu # Application menu replacement
        gnomeExtensions.appindicator # System tray icons support
        gnomeExtensions.gsconnect # KDE Connect integration
        gnomeExtensions.dash-to-dock # Dock for applications
        gnomeExtensions.clipboard-indicator # Clipboard manager
      ];

      # Enable and configure extensions via dconf
      dconf.settings = {
        "org/gnome/shell" = {
          enabled-extensions = [
            pkgs.gnomeExtensions.blur-my-shell.extensionUuid
            pkgs.gnomeExtensions.just-perfection.extensionUuid
            pkgs.gnomeExtensions.arc-menu.extensionUuid
            pkgs.gnomeExtensions.appindicator.extensionUuid
            pkgs.gnomeExtensions.gsconnect.extensionUuid
          ];
        };

        # Configure blur-my-shell extension
        "org/gnome/shell/extensions/blur-my-shell" = {
          brightness = 0.75;
          noise-amount = 0;
        };

        # Set dark mode as default
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
    };
  };

  # GNOME with experimental features enabled
  # Usage: FTS.gnome-desktop.experimental
  FTS.gnome-desktop.experimental = {
    description = "GNOME desktop with experimental features enabled";

    includes = [ FTS.gnome ];

    nixos = {
      # Enable experimental GNOME features
      programs.dconf.profiles.user.databases = [
        {
          settings = {
            "org/gnome/mutter" = {
              experimental-features = [
                "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
                "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays
                "xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
              ];
            };
          };
        }
      ];
    };
  };
}

