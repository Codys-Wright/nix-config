# SDDM display manager with Wayland support
{ FTS, ... }:
{
  FTS.desktop._.display-manager._.sddm = {
    description = "SDDM display manager with Wayland backend and autologin";

    nixos =
      { pkgs, lib, ... }:
      {
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          autoNumlock = true;
        };

        # Default session for SDDM to offer
        services.displayManager.defaultSession = "niri";
      };
  };
}
