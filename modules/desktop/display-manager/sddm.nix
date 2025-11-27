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

    nixos = { pkgs, lib, ... }: {
      # Enable SDDM display manager
      services.displayManager.sddm = {
        enable = true;
      };

      # Install SDDM configuration tools
      environment.systemPackages = with pkgs; [
        kdePackages.sddm-kcm # Configuration module for SDDM
      ];
    };
  };

  # SDDM with Wayland support
  # Usage: den.aspects.sddm.wayland
  den.aspects.sddm.wayland = {
    description = "SDDM display manager with Wayland support";

    includes = [ den.aspects.sddm ];

    nixos = { pkgs, lib, ... }: {
      # Enable Wayland support in SDDM
      services.displayManager.sddm.wayland.enable = true;
    };
  };
}

