{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.gnome;
in
{
  options.${namespace}.desktop.gnome = with types; {
    enable = mkBoolOpt false ''
      Whether or not to use GNOME as the desktop environment.
      
      When enabled, this module will:
      - Enable X11 server
      - Configure GDM display manager
      - Enable GNOME desktop environment
      - Set up basic GNOME services and applications
      
      Example:
      ```nix
      FTS-FLEET = {
        desktop.gnome = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    # Essential GNOME packages
    environment.systemPackages = with pkgs; [
      # Core GNOME packages
      gnome.gnome-shell
      gnome.gnome-control-center
      gnome.gnome-settings-daemon
      gnome.gnome-terminal
      gnome.nautilus
      gnome.gedit
      gnome.gnome-calculator
      gnome.gnome-system-monitor
      gnome.gnome-disk-utility
      gnome.gnome-software
      gnome.gnome-tweaks
      
      # GNOME extensions and utilities
      gnome.gnome-shell-extensions
      gnome.gnome-backgrounds
      gnome.gnome-themes-extra
      
      # Additional GNOME applications
      gnome.evolution
      gnome.epiphany
      gnome.gnome-music
      gnome.gnome-photos
      gnome.gnome-maps
      gnome.gnome-weather
      gnome.gnome-calendar
      gnome.gnome-contacts
      gnome.gnome-clocks
      gnome.gnome-characters
      gnome.gnome-font-viewer
      gnome.gnome-logs
      gnome.gnome-boxes
      gnome.gnome-builder
      
      # Development tools
      gnome.gnome-builder
      gnome.devhelp
      
      # Multimedia
      gnome.totem
      gnome.cheese
      gnome.rythmbox
    ];

    # GNOME environment configuration
    environment.sessionVariables = {
      GNOME_SHELL_SESSION_MODE = "user";
      GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = "false";
      GNOME_SHELL_DISABLE_EXTENSION_RELOAD = "false";
    };

    services = {
      xserver.enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      
      # GNOME services
      gnome = {
        core-developer-tools.enable = true;
        core-utilities.enable = true;
        games.enable = true;
        gnome-initial-setup.enable = true;
        gnome-online-accounts.enable = true;
        gnome-user-share.enable = true;
        rygel.enable = true;
        seahorse.enable = true;
        sushi.enable = true;
        tracker.enable = true;
        tracker-miners.enable = true;
      };
    };
  };
} 