# Animation Preset: Dynamic
# From HyDE Project
# Dynamic responsive animations
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.presets._.animations._.dynamic = {
    description = "Dynamic animations (from HyDE)";

    settings = {
      animations = {
        enabled = true;
        
        bezier = [
          "overshot, 0.05, 0.9, 0.1, 1.05"
          "smoothOut, 0.36, 0, 0.66, -0.56"
          "smoothIn, 0.25, 1, 0.5, 1"
        ];
        
        animation = [
          "windows, 1, 5, overshot, slide"
          "windowsOut, 1, 4, smoothOut, slide"
          "windowsMove, 1, 4, default"
          "border, 1, 10, default"
          "fade, 1, 10, smoothIn"
          "fadeDim, 1, 10, smoothIn"
          "workspaces, 1, 6, default"
        ];
      };
    };
  };
}
