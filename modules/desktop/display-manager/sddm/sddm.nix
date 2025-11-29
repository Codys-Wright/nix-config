# SDDM Display Manager
# Simple Desktop Display Manager - commonly used with KDE Plasma
{
  den,
  FTS,
  ...
}:
{
  # Base SDDM display manager
  FTS.sddm = {
    description = "SDDM display manager";

    nixos = {
      # Enable SDDM display manager
      services.displayManager.sddm = {
        enable = true;
      };
    };
  };

  # SDDM with Wayland support
  # Usage: FTS.sddm.wayland
  FTS.sddm.wayland = {
    description = "SDDM display manager with Wayland support";

    nixos = {
      # Enable SDDM display manager
      services.displayManager.sddm = {
        enable = true;
        # Enable Wayland support in SDDM
        wayland.enable = true;
      };
    };
  };
}

