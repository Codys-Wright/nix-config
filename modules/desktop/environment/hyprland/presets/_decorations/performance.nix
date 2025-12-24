# Performance Decoration Preset - Everything disabled
# Use case: Gaming, low-end hardware, maximum FPS
{
  name = "performance";
  settings = {
    decoration = {
      rounding = 0;
      active_opacity = 1.0;
      inactive_opacity = 1.0;
      fullscreen_opacity = 1.0;
      
      blur = {
        enabled = false;
      };
      
      shadow = {
        enabled = false;
      };
      
      dim_inactive = false;
    };
    
    general = {
      border_size = 0;
    };
  };
}
