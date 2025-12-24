# Dim Focus Decoration Preset - Heavy dimming of inactive windows
# Use case: Reduce distractions, focus on active window
{
  name = "dim-focus";
  settings = {
    decoration = {
      rounding = 10;
      active_opacity = 1.0;
      inactive_opacity = 0.85;
      fullscreen_opacity = 1.0;
      
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
      };
      
      shadow = {
        enabled = true;
        range = 5;
        render_power = 2;
      };
      
      dim_inactive = true;
      dim_strength = 0.30;
    };
    
    general = {
      border_size = 2;
    };
  };
}
