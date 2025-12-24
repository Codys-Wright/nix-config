# Hyprlock - Hyprland screen locker configuration
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.plugins._.hyprlock = {
    description = "Hyprlock screen locker configuration for Hyprland";

    homeManager = {
      programs.hyprlock = {
        enable = true;
        
        settings = {
          general = {
            disable_loading_bar = false;
            hide_cursor = true;
            grace = 0;
            no_fade_in = false;
          };

          background = [
            {
              path = "screenshot"; # Use screenshot as background
              blur_passes = 3;
              blur_size = 8;
            }
          ];

          input-field = [
            {
              size = "200, 50";
              position = "0, -80";
              monitor = "";
              dots_center = true;
              fade_on_empty = false;
              font_color = "rgb(202, 211, 245)";
              inner_color = "rgb(91, 96, 120)";
              outer_color = "rgb(24, 25, 38)";
              outline_thickness = 5;
              placeholder_text = "Password...";
              shadow_passes = 2;
            }
          ];
        };
      };
    };
  };
}
