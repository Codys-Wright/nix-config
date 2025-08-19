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
  cfg = config.${namespace}.services.selfhost.media.audiobookshelf;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.media.audiobookshelf = with types; {
    enable = mkBoolOpt false "Enable AudioBookshelf (audiobook management)";
    
    dataDir = mkOpt str "/mnt/data/audiobookshelf" "Data directory for AudioBookshelf";
    
    url = mkOpt str "audiobooks.${selfhostCfg.baseDomain}" "URL for AudioBookshelf service";
    
    homepage = {
      name = mkOpt str "AudioBookshelf" "Name shown on homepage";
      description = mkOpt str "Self-hosted audiobook and podcast server" "Description shown on homepage";
      icon = mkOpt str "audiobookshelf.svg" "Icon shown on homepage";
      category = mkOpt str "Media" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Mount data directory
    fileSystems."/var/lib/audiobookshelf" = {
      device = cfg.dataDir;
      options = [ "bind" ];
    };

    services.audiobookshelf = {
      enable = true;
      host = "127.0.0.1";
      port = 8008;
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8008
      '';
    };
    
    environment.systemPackages = [ pkgs.audiobookshelf ];
  };
}
