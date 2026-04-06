# SDDM display manager with MacTahoe theme
{ FTS, ... }:
{
  FTS.desktop._.display-manager._.sddm = {
    description = "SDDM display manager with Wayland backend and MacTahoe-Dark theme";

    nixos =
      { pkgs, ... }:
      let
        mactahoeKde = pkgs.callPackage ../../../packages/mactahoe/kde-theme.nix { };
      in
      {
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          autoNumlock = true;
          theme = "MacTahoe-Dark";
        };

        environment.systemPackages = [ mactahoeKde ];
      };
  };
}
