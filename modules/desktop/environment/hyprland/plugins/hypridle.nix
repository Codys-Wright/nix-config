# Hypridle - Hyprland idle daemon configuration
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.plugins._.hypridle = {
    description = "Hypridle idle daemon configuration for Hyprland";

    homeManager = {
      services.hypridle = {
        enable = true;
        
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock"; # Avoid starting multiple hyprlock instances
            before_sleep_cmd = "loginctl lock-session"; # Lock before suspend
            after_sleep_cmd = "hyprctl dispatch dpms on"; # Turn on display after resume
          };

          listener = [
            {
              timeout = 300; # 5 minutes
              on-timeout = "loginctl lock-session"; # Lock screen
            }
            {
              timeout = 330; # 5.5 minutes
              on-timeout = "hyprctl dispatch dpms off"; # Turn off display
              on-resume = "hyprctl dispatch dpms on"; # Turn on display
            }
            {
              timeout = 600; # 10 minutes
              on-timeout = "systemctl suspend"; # Suspend system
            }
          ];
        };
      };
    };
  };
}
