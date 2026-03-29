# SDDM Display Manager
# Simple Desktop Display Manager - commonly used with KDE Plasma
{
  FTS,
  ...
}:
{
  # Base SDDM display manager
  FTS.sddm = {
    description = "SDDM display manager";

    nixos =
      { pkgs, ... }:
      {
        # Enable SDDM display manager
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
          theme = "MacTahoe-Dark";
          extraPackages = [
            pkgs.kdePackages.plasma-desktop
            pkgs.kdePackages.qtsvg
          ];
        };

        # Ensure SDDM theme package is available
        environment.systemPackages = [
          (pkgs.callPackage ../../../../packages/mactahoe/kde-theme.nix {
            colorVariants = [ "dark" ];
          })
        ];
      };
  };
}
