# Crazy Workflow Profile - Wild animations and maximum effects
{
  name = "Crazy";
  animation = "lime-frenzy";
  shader = "vibrance.frag";
  decoration = "neon";
  layout = "dwindle-default";
  cursor = "default";
  window-rules = "default";
  workspace-rules = "default";
  settings = {
    decoration = {
      blur.enabled = true;
      blur.size = 10;
      blur.passes = 4;
      blur.vibrancy = 0.2;
      blur.vibrancy_darkness = 0.5;
      shadow.enabled = true;
      shadow.range = 20;
      shadow.render_power = 4;
      shadow.color = "rgba(ff00ffee)";
      rounding = 20;
      active_opacity = 0.9;
      inactive_opacity = 0.7;
    };
    
    misc = {
      disable_hyprland_logo = false;
      disable_splash_rendering = false;
      vfr = false;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;
    };
  };
}
