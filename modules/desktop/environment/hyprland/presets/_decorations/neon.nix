# Neon Decoration Preset - Bright, colorful borders, no blur
# Use case: RGB aesthetic, gaming
{
  name = "neon";
  settings = {
    decoration = {
      rounding = 8;
      active_opacity = 1.0;
      inactive_opacity = 0.95;
      fullscreen_opacity = 1.0;
      
      blur = {
        enabled = false;
      };
      
      shadow = {
        enabled = true;
        range = 20;
        render_power = 4;
      };
      
      dim_inactive = false;
    };
    
    general = {
      border_size = 3;
    };
  };
}
