# Animation Preset: LimeFrenzy
# From HyDE Project
# LimeFrenzy style animations
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.presets._.animations._.lime-frenzy = {
    description = "LimeFrenzy animations (from HyDE)";

    settings = {
      animations = {
        enabled = true;
        
        bezier = [
          "fluent_decel, 0.1, 1, 0, 1"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "easeinoutsine, 0.37, 0, 0.63, 1"
        ];
        
        animation = [
          "windowsIn, 1, 1.7, easeOutCubic, popin 30%"
          "windowsOut, 1, 1.7, fluent_decel, popin 70%"
          "windowsMove, 1, 2, easeinoutsine, slide"
          "fadeIn, 1, 3, easeOutCubic"
          "fadeOut, 1, 3, easeOutCubic"
          "fadeSwitch, 1, 3, easeOutCirc"
          "fadeShadow, 1, 10, easeOutCirc"
          "fadeDim, 1, 4, fluent_decel"
          "border, 1, 2.7, easeOutCirc"
          "workspaces, 1, 3, easeOutCubic, slide"
        ];
      };
    };
  };
}
