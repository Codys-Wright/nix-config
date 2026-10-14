# SDDM display manager with MacTahoe theme
{ fleet, ... }:
{
  fleet.desktop._.display-manager._.sddm = {
    description = "SDDM display manager with Wayland backend and MacTahoe-Dark theme";

    nixos =
      { lib, pkgs, ... }:
      let
        mactahoeKde = pkgs.mactahoe-kde-theme;
      in
      {
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          autoNumlock = true;
          # Overridable: hosts on the Loft shell use Loft's login screen.
          # Above mkDefault, which Plasma 6 uses for "breeze".
          theme = lib.mkOverride 900 "MacTahoe-Dark";
        };

        environment.systemPackages = [ mactahoeKde ];
      };
  };
}
