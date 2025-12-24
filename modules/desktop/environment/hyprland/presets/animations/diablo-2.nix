# Animation Preset: Diablo-2
# From HyDE Project
# Credit: https://github.com/Itz-Abhishek-Tiwari
# Bouncy sliding animations variant
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.presets._.animations._.diablo-2 = {
    description = "Diablo-2 animations (from HyDE - bouncy slide variant)";

    settings = {
      animations = {
        enabled = true;
        
        bezier = [
          "linear, 0, 0, 1, 1"
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 0.9, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "liner, 1, 1, 1, 1"
          "overshot, 0.13, 0.99, 0.29, 1.1"
        ];
        
        animation = [
          "windowsIn, 1, 6, winIn, slide"
          "windowsOut, 1, 5, winOut, slide"
          "windowsMove, 1, 5, wind, slide"
          "border, 1, 10, default"
          "borderangle, 1, 100, linear, loop"
          "fade, 1, 8, default"
          "workspaces, 1, 6, overshot, slide"
        ];
      };
    };
  };
}
