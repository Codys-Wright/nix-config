# Glass Decoration Preset - Heavy transparency and blur
# Use case: Aesthetics, showing off
{
  name = "glass";
  settings = {
    decoration = {
      rounding = 12;
      active_opacity = 0.92;
      inactive_opacity = 0.80;
      fullscreen_opacity = 1.0;
      
      blur = {
        enabled = true;
        size = 10;
        passes = 4;
        new_optimizations = true;
        ignore_opacity = true;
        popups = true;
      };
      
      shadow = {
        enabled = true;
        range = 15;
        render_power = 3;
      };
      
      dim_inactive = true;
      dim_strength = 0.15;
    };
    
    general = {
      border_size = 2;
    };
  };
}
