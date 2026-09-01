# SDDM display manager with MacTahoe theme
{ fleet, ... }:
{
  fleet.desktop._.display-manager._.sddm = {
    description = "SDDM display manager with Wayland backend and MacTahoe-Dark theme";

    # SDDM wedges (active, but dark forever) when its last DRM output vanishes
    # under the running greeter. The watchdog restarts it when an output
    # returns. See docs/sddm-no-greeter-incident.md.
    includes = [ fleet.desktop._.display-manager._.sddm-output-watchdog ];

    nixos =
      { pkgs, ... }:
      let
        mactahoeKde = pkgs.mactahoe-kde-theme;
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
