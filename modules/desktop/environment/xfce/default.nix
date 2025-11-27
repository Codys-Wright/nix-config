# XFCE Desktop Environment
# Provides NixOS configuration for XFCE
# Note: Display manager should be configured separately
{
  den,
  ...
}:
{
  # Base XFCE desktop environment
  den.aspects.xfce-desktop = {
    description = "XFCE desktop environment";

    nixos = {
      # Enable X11 server (required for XFCE)
      services.xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
          xfce.enable = true;
        };
      };

      # Set XFCE as default session
      services.displayManager.defaultSession = "xfce";
    };
  };
}

