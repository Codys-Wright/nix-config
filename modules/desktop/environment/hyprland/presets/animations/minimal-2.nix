# Animation Preset: Minimal-2
# From HyDE Project
# Very minimal, quick animations
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.presets._.animations._.minimal-2 = {
    description = "Minimal-2 animations (from HyDE - very minimal)";

    settings = {
      animations = {
        enabled = true;
        
        bezier = [
          "simple, 0.16, 1, 0.3, 1"
        ];
        
        animation = [
          "windows, 1, 3, simple, slide"
          "fade, 1, 3, simple"
          "workspaces, 1, 3, simple, slide"
        ];
      };
    };
  };
}
