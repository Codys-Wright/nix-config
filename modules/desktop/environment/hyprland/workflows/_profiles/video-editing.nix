# Video Editing Workflow Profile
{
  name = "VideoEditing";
  animation = "optimized";
  shader = null;
  decoration = "glass";
  layout = "dwindle-default";
  cursor = "productivity";
  window-rules = "default";
  workspace-rules = "default";
  settings = {
    decoration = {
      blur.enabled = true;
      active_opacity = 0.95;
      inactive_opacity = 0.85;
      rounding = 8;
    };

    general = {
      gaps_in = 4;
      gaps_out = 8;
    };

    misc = {
      vfr = true;
      focus_on_activate = true;
    };

    # Workspace behavior overrides for video editing
    workspace = [
      "name:VideoEditing-Primary, default:true, gapsin:2, gapsout:4"    # Main editing workspace
      "name:VideoEditing-Secondary, gapsin:0, gapsout:2"               # Preview workspace (compact)
      "name:VideoEditing-Tertiary, gapsin:4, gapsout:8"                # Tools workspace (spacious)
      "name:Media, gapsin:2, gapsout:4"                                # Media library
      "name:Research, gapsin:3, gapsout:6"                             # Reference materials
    ];
  };
}