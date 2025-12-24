# Hyprland monitor configuration
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.config._.monitors = {
    description = "Hyprland monitor configuration";

    homeManager = {
      wayland.windowManager.hyprland.settings = {
        monitor = [
          "DP-4, 5120x1440@240, 0x0, 1.00"
          "DP-5,2560x1440@180,0x1440,1.00"
          "HDMI-A-2,2560x1440@60,2560x1440,1.00"
        ];
      };
    };
  };
}
