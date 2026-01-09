# Hyprland environment aggregator - Main entry point
{
  FTS,
  lib,
  pkgs,
  ...
}:
{
  FTS.desktop._.environment._.hyprland = {
    description = ''
      Hyprland desktop environment with modular configuration.
    '';

    nixos =
      { pkgs, ... }:
      {
        # Enable Hyprland at system level
        programs.hyprland = {
          enable = true;
        };

        # Install Hyprland ecosystem packages
        environment.systemPackages = with pkgs; [
          hyprpicker
          hyprcursor
          hypridle
          hyprpaper
          hyprsunset
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        # Enable Hyprland window manager
        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;

          # Enable workflow system (profiles loaded from workflows module)
          workflows.enable = true;
        };

        # XDG Portal configuration for proper dark mode and desktop integration
        # This is critical for GTK apps to respect dark mode on NixOS 25.05+
        xdg.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gnome
          ];
          configPackages = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gnome
          ];
          config.common = {
            default = [
              "gnome"
              "hyprland"
              "gtk"
            ];
            # Use GNOME portal for Settings (required for dark mode preference)
            "org.freedesktop.impl.portal.Settings" = "gnome";
          };
        };

        # dconf settings for GTK dark mode preference
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "MacTahoe-Dark-Blue";
            icon-theme = "MacTahoe-Blue";
          };
        };

        # GTK configuration (use mkForce to override Stylix defaults)
        gtk = {
          enable = true;
          theme = {
            name = lib.mkForce "MacTahoe-Dark-Blue";
          };
          iconTheme = {
            name = lib.mkForce "MacTahoe-Blue";
          };
          cursorTheme = {
            name = lib.mkForce "MacTahoe-dark-cursors";
            size = lib.mkForce 24;
          };
          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = true;
          };
          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = true;
          };
        };
      };

    # Include all sub-aspects by default
    includes = [
      # Core configuration aspects
      FTS.desktop._.environment._.hyprland._.config._.binds
      FTS.desktop._.environment._.hyprland._.config._.monitors
      FTS.desktop._.environment._.hyprland._.config._.settings
      FTS.desktop._.environment._.hyprland._.config._.rules

      # Workflow system
      FTS.desktop._.environment._.hyprland._.workflows

      # App aspects
      FTS.desktop._.environment._.hyprland._.apps._.walker

      # Plugin aspects
      FTS.desktop._.environment._.hyprland._.plugins._.dunst
      FTS.desktop._.environment._.hyprland._.plugins._.hyprcursor
      FTS.desktop._.environment._.hyprland._.plugins._.hypridle
      FTS.desktop._.environment._.hyprland._.plugins._.hyprpaper
      FTS.desktop._.environment._.hyprland._.plugins._.hyprlock
      FTS.desktop._.environment._.hyprland._.plugins._.pyprland

      # Script aspects
      FTS.desktop._.environment._.hyprland._.scripts._.run-or-raise
      FTS.desktop._.environment._.hyprland._.scripts._.workflow-switcher
      FTS.desktop._.environment._.hyprland._.scripts._.hyprland-manager
    ];
  };
}
