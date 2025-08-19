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
  cfg = config.${namespace}.services.selfhost.media.navidrome;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.media.navidrome = with types; {
    enable = mkBoolOpt false "Enable Navidrome (music streaming)";
    
    musicFolder = mkOpt str "/mnt/data/navidrome/music" "Music library directory";
    
    dataDir = mkOpt str "/mnt/data/navidrome/data" "Data directory for Navidrome";
    
    url = mkOpt str "music.${selfhostCfg.baseDomain}" "URL for Navidrome service";
    
    homepage = {
      name = mkOpt str "Navidrome" "Name shown on homepage";
      description = mkOpt str "Modern Music Server and Streamer" "Description shown on homepage";
      icon = mkOpt str "navidrome.svg" "Icon shown on homepage";
      category = mkOpt str "Media" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Optional SOPS secrets for Last.fm integration
    sops.secrets = mkIf (config.sops.secrets ? last-fm-key) {
      last-fm-key = {
        owner = "navidrome";
      };
      last-fm-secret = {
        owner = "navidrome";
      };
    };

    services.navidrome = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
      settings = {
        Address = "127.0.0.1";
        Port = 4533;
        MusicFolder = cfg.musicFolder;
        DataFolder = cfg.dataDir;
        BaseURL = "https://${cfg.url}";
      } // optionalAttrs (config.sops.secrets ? last-fm-key) {
        LastFM.ApiKey = "$(cat ${config.sops.secrets.last-fm-key.path})";
        LastFM.Secret = "$(cat ${config.sops.secrets.last-fm-secret.path})";
      };
    };
    
    # Optional MPD integration
    services.mpd = mkIf cfg.enable {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
      musicDirectory = cfg.musicFolder;
      dataDir = cfg.dataDir;
      network = {
        port = 6600;
        listenAddress = "127.0.0.1";
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:4533
      '';
    };
  };
}
