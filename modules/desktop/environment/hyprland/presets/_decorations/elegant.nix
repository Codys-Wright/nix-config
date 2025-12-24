# Elegant Decoration Preset - Balanced, professional look
# Use case: General productivity
{
  name = "elegant";
  settings = {
    decoration = {
      rounding = 10;
      active_opacity = 0.95;
      inactive_opacity = 0.90;
      fullscreen_opacity = 1.0;
      
      blur = {
        enabled = true;
        size = 5;
        passes = 2;
        new_optimizations = true;
      };
      
      shadow = {
        enabled = true;
        range = 8;
        render_power = 2;
      };
      
      dim_inactive = true;
      dim_strength = 0.05;
    };
    
    general = {
      border_size = 2;
    };
  };
}
