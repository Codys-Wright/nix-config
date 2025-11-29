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

        wayland.enable = true;
      };
    };
  };
}

