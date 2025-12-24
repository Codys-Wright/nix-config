# Aesthetic Workflow Profile - Beautiful eye candy with heavy effects
{
  name = "Aesthetic";
  animation = "dynamic";
  shader = null;
  decoration = "glass";
  layout = "master-center";
  cursor = "default";
  window-rules = "default";
  workspace-rules = "default";
  settings = {
    decoration = {
      blur.enabled = true;
      blur.size = 8;
      blur.passes = 3;
      blur.new_optimizations = true;
      shadow.enabled = true;
      shadow.range = 12;
      shadow.render_power = 4;
      rounding = 16;
      active_opacity = 0.95;
      inactive_opacity = 0.85;
    };
    
    misc = {
      disable_hyprland_logo = false;
      disable_splash_rendering = false;
      vfr = false;
    };
  };
}
