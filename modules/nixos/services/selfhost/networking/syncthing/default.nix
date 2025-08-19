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
  cfg = config.${namespace}.services.selfhost.networking.syncthing;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.networking.syncthing = with types; {
    enable = mkBoolOpt false "Enable Syncthing (file synchronization)";
    
    dataDir = mkOpt str "/mnt/data/syncthing" "Data directory for Syncthing";
    
    url = mkOpt str "syncthing.${selfhostCfg.baseDomain}" "URL for Syncthing web interface";
    
    homepage = {
      name = mkOpt str "Syncthing" "Name shown on homepage";
      description = mkOpt str "Continuous file synchronization" "Description shown on homepage";
      icon = mkOpt str "syncthing.svg" "Icon shown on homepage";
      category = mkOpt str "Networking" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      guiAddress = "127.0.0.1:8384";
      dataDir = cfg.dataDir;
      openDefaultPorts = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") (mkMerge [
      {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8384
        '';
      }
      (mkIf (selfhostCfg.cloudflare.dnsCredentialsFile != null && selfhostCfg.acme.email != "") {
        useACMEHost = selfhostCfg.baseDomain;
      })
    ]);
  };
}
