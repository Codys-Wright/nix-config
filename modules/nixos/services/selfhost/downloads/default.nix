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
  cfg = config.${namespace}.services.selfhost.downloads;
in
{
  options.${namespace}.services.selfhost.downloads = with types; {
    enable = mkBoolOpt false "Enable download services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.downloads = {
      deluge.enable = mkDefault true;
      jdownloader.enable = mkDefault true;  # Re-enabled with Flatpak instead of containers
      qbittorrent-enhanced.enable = mkDefault true;
      sabnzbd.enable = mkDefault true;
      slskd.enable = mkDefault true;
    };
  };
} 