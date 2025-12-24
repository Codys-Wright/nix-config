# Animation Preset: Disable
# From HyDE Project
# Disables all animations for maximum performance
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.presets._.animations._.disable = {
    description = "Disabled animations (from HyDE)";

    settings = {
      animations = {
        enabled = false;
      };
    };
  };
}
