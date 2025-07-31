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
  cfg = config.${namespace}.desktop.hyprland;
in
{
  options.${namespace}.desktop.hyprland = with types; {
    enable = mkBoolOpt false "Whether or not to use Hyprland as the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
    };
    programs.hyprland.enable = true;

    services.xserver.displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    services = {
      gvfs.enable = true;
      devmon.enable = true;
      upower.enable = true;
      gnome = {
        glib-networking.enable = true;
        gnome-online-accounts.enable = true;
      };
    };

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
    };

    zeus = {
      programs = {
        dconf = enabled;
        kde-connect = enabled;
        nautilus = enabled;
      };
      services = {
        greetd = disabled;
        polkit-gnome = enabled;
      };
    };
  };
}
