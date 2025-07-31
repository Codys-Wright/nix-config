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
      xserver.enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;
    };
  };
}
