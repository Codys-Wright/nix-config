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
      - Enable GDM display manager
      - Enable GNOME desktop environment (Wayland by default)
      - Install useful GNOME extensions
      
      Example:
      ```nix
      ${namespace} = {
        desktop.gnome = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    # Essential GNOME packages and extensions
    environment.systemPackages = with pkgs; [
      # Core GNOME applications (top-level packages)
      gnome-shell
      gnome-control-center
      gnome-terminal
      nautilus
      gedit
      gnome-calculator
      gnome-system-monitor
      gnome-software
      gnome-tweaks
      
      # Useful GNOME extensions
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection
      gnomeExtensions.arc-menu
      gnomeExtensions.dash-to-dock
      gnomeExtensions.appindicator
      gnomeExtensions.gsconnect
    ];

    # GNOME services (as of 25.11)
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
} 