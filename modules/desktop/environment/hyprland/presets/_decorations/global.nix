# Global Decoration Settings
# Applied to all decoration presets
{
  name = "global";
  settings = {
    decoration = {
      # Basic settings that most presets will use
      rounding = 10;
      active_opacity = 0.9;
      inactive_opacity = 0.8;
      fullscreen_opacity = 1.0;

      # Default blur settings
      blur = {
        enabled = true;
        size = 8;
        passes = 3;
        new_optimizations = true;
        ignore_opacity = false;
        popups = true;
      };

      # Default shadow settings
      shadow = {
        enabled = true;
        range = 20;
        render_power = 3;
        color = "rgba(00000099)";
      };

      # Default dim settings
      dim_inactive = false;
      dim_strength = 0.1;

      # Other defaults
      border_part_of_window = true;
    };
  };
}