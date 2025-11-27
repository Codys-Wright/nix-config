# KDE Plasma 6 Desktop Environment
# Provides NixOS configuration for KDE Plasma 6
# Note: Display manager should be configured separately (e.g., den.aspects.sddm.wayland)
{
  den,
  lib,
  ...
}:
{
  # Base KDE Plasma 6 desktop environment
  den.aspects.kde-desktop = {
    description = "KDE Plasma 6 desktop environment";

    nixos = {
      # Enable KDE Plasma 6 desktop manager
      services.desktopManager.plasma6.enable = true;
      
      # Don't set SSH askPassword (override default from plasma6 module)
      programs.ssh.askPassword = lib.mkForce "";
    };
  };

  # KDE with RDP support (X11-based remote desktop)
  # Note: RDP requires X11 instead of Wayland
  # Usage: den.aspects.kde-desktop.rdp
  den.aspects.kde-desktop.rdp = {
    description = "KDE Plasma 6 with RDP remote desktop support (X11)";

    includes = [ den.aspects.kde-desktop ];

    nixos = {
      # Enable X11 for RDP support
      services.xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      # Configure xrdp for remote desktop access
      services.xrdp = {
        defaultWindowManager = "startplasma-x11";
        enable = true;
        openFirewall = true;
      };
    };
  };
}

