{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.kde;
in
{
  options.${namespace}.desktop.kde = with types; {
    enable = mkBoolOpt false ''
      Whether or not to use KDE Plasma as the desktop environment.
      
      When enabled, this module will:
      - Enable X11 server
      - Configure SDDM display manager
      - Enable KDE Plasma 6 desktop environment
      - Set up basic KDE services and applications
      
      Example:
      ```nix
      FTS-FLEET = {
        desktop.kde = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {

                services = {
                desktopManager.plasma6.enable = true;
                displayManager.sddm.enable = true;
                displayManager.sddm.wayland.enable = true;

                };

                environment.systemPackages = with pkgs;
                        [
                                kdePackages.discover
                                kdePackages.kcalc
                                kdePackages.kcharselect
                                kdePackages.kcolorchooser
                                kdePackages.kolourpaint
                                kdePackages.ksystemlog
                                kdePackages.sddm-kcm
                                kdiff3
                                kdePackages.isoimagewriter
                                kdePackages.partitionmanager
                                hardinfo2
                                haruna
                                wayland-utils
                                wl-clipboard

                        ];

  };


}
