# Hyprland window rules, workspace rules, and layer rules
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.config._.rules = {
    description = "Hyprland window rules, workspace rules, and layer rules";

    homeManager = {
      wayland.windowManager.hyprland.settings = {
        # Window rules (v2 format recommended)
        # Example: windowrulev2 = float, class:^(kitty)$, title:^(floating)$
        windowrulev2 = [
          # Add your window rules here
        ];

        # Workspace rules
        # Example: workspace = 1, monitor:DP-1, default:true
        workspace = [
          # Add your workspace rules here
        ];

        # Layer rules
        # Example: layerrule = blur, waybar
        layerrule = [
          # Add your layer rules here
        ];
      };
    };
  };
}
