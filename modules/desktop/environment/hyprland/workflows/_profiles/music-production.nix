# Music Production Workflow Profile - Optimized for audio production
{
  name = "Music-Production";
  animation = "minimal-1";
  shader = null;
  decoration = "elegant";
  layout = "master-center";
  cursor = "productivity";
  window-rules = "default";
  workspace-rules = "default";
  settings = {
    decoration = {
      blur.enabled = false;
      active_opacity = 1.0;
      inactive_opacity = 0.9;
      rounding = 6;
    };

    general = {
      gaps_in = 3;
      gaps_out = 5;
    };

    master = {
      new_status = "slave";
      mfact = 0.6;
    };

    misc = {
      vfr = false;  # Fixed FPS for audio sync
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
    };

    # Workspace behavior overrides for music production
    workspace = [
      "name:MusicProduction-Primary, default:true, gapsin:3, gapsout:5"    # Main DAW workspace
      "name:MusicProduction-Secondary, gapsin:2, gapsout:4"               # Mixer/effects (compact)
      "name:MusicProduction-Tertiary, gapsin:4, gapsout:6"                # Instruments/samples
      "name:AI, gapsin:3, gapsout:5"                                     # AI tools/music generation
      "name:Notes, gapsin:4, gapsout:8"                                  # Song notes/lyrics (spacious)
    ];
  };
}
