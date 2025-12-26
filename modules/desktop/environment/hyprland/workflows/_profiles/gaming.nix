# Gaming Workflow Profile - Maximum performance, minimal effects
{
  name = "Gaming";
  animation = "fast";
  shader = "vibrance.frag";
  decoration = "performance";
  layout = "dwindle-default";
  cursor = "gaming";
  window-rules = "default";
  workspace-rules = "default";
   settings = {
     decoration = {
       blur.enabled = false;
       shadow.enabled = false;
       rounding = 0;
     };

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      vfr = false;
      vrr = 1;
    };

    # Workspace behavior overrides for gaming
    workspace = [
      "name:VideoGame, default:true"      # Make VideoGame the default workspace
      "name:VideoGameLauncher, gapsin:0, gapsout:0"  # No gaps for launcher
      "name:Communication, gapsin:0, gapsout:0"      # Compact chat layout
    ];
   };
}
