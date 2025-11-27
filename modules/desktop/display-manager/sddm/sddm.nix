# SDDM Display Manager
# Simple Desktop Display Manager - commonly used with KDE Plasma
{
  den,
  ...
}:
{
  # Base SDDM display manager
  den.aspects.sddm = {
    description = "SDDM display manager";

    nixos = {
      # Enable SDDM display manager
      services.displayManager.sddm = {
        enable = true;
      };
    };
  };

  # SDDM with Wayland support
  # Usage: den.aspects.sddm.wayland
  den.aspects.sddm.wayland = {
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

