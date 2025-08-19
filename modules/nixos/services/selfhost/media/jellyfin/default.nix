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
  cfg = config.${namespace}.services.selfhost.media.jellyfin;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.media.jellyfin = with types; {
    enable = mkBoolOpt false "Enable Jellyfin (media server)";
    
    dataDir = mkOpt str "/mnt/storage/jellyfin" "Data directory for Jellyfin";
    
    url = mkOpt str "jellyfin.${selfhostCfg.baseDomain}" "URL for Jellyfin service";
    
    homepage = {
      name = mkOpt str "Jellyfin" "Name shown on homepage";
      description = mkOpt str "The Free Software Media System" "Description shown on homepage";
      icon = mkOpt str "jellyfin.svg" "Icon shown on homepage";
      category = mkOpt str "Media" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      dataDir = cfg.dataDir;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8096
      '';
    };
  };
}
