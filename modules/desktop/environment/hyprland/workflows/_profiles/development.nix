# Development Workflow Profile - Clean and functional for coding
{
  name = "Development";
  animation = "optimized";
  shader = null;
  decoration = "minimal";
  layout = "master-left";
  cursor = "productivity";
  window-rules = "default";
  workspace-rules = "default";
  settings = {
    decoration = {
      blur.enabled = false;
      active_opacity = 0.95;
      inactive_opacity = 0.85;
      rounding = 5;
    };

    general = {
      gaps_in = 5;
      gaps_out = 8;
      border_size = 2;
    };

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      vfr = true;
      focus_on_activate = true;
    };

    # Workspace behavior overrides for development
    workspace = [
      "name:Dev-Preview, default:true, gapsin:5, gapsout:8, bordersize:2"    # Main coding workspace
      "name:Notes, gapsin:4, gapsout:6, bordersize:1"                       # Documentation/notes
      "name:Communication, gapsin:3, gapsout:5"                            # Chat/communication
      "name:AI, gapsin:4, gapsout:6"                                       # AI assistance/tools
      "name:Research, gapsin:5, gapsout:8"                                 # Research/documentation
    ];
  };
}
