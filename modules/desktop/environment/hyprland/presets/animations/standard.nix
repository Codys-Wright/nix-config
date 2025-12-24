# Animation Preset: Standard
# From HyDE Project
# Standard balanced animations
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.presets._.animations._.standard = {
    description = "Standard animations (from HyDE)";

    settings = {
      animations = {
        enabled = true;

        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
        ];

        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
    };
  };
}
