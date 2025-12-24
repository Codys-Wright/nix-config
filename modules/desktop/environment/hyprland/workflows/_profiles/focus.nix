# Focus Workflow Profile - Minimal distractions for deep work
{
  name = "Focus";
  animation = "minimal-1";
  shader = null;
  decoration = "dim-focus";
  layout = "master-center";
  cursor = "default";
  window-rules = "default";
  workspace-rules = "default";
  settings = {
    decoration = {
      blur.enabled = false;
      shadow.enabled = false;
      dim_inactive = true;
      dim_strength = 0.1;
    };
    
    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      vfr = true;
    };
  };
}
