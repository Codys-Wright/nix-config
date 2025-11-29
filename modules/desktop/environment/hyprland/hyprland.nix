# Hyprland Window Manager
# Provides NixOS configuration for Hyprland Wayland compositor
# Note: Display manager should be configured separately (e.g., FTS.sddm.wayland)
{
  den,
  FTS,
  ...
}:
{
  # Base Hyprland window manager
  FTS.hyprland = {
    description = "Hyprland Wayland compositor";

    nixos = {
      # Enable Hyprland
      programs.hyprland = {
        enable = true;
      };
    };
  };
}

