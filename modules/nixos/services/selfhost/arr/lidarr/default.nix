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
  cfg = config.${namespace}.services.selfhost.arr.lidarr;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.arr.lidarr = with types; {
    enable = mkBoolOpt false "Enable Lidarr (music collection manager)";
    
    configDir = mkOpt str "/var/lib/lidarr" "Configuration directory for Lidarr";
    
    url = mkOpt str "lidarr.${selfhostCfg.baseDomain}" "URL for Lidarr service";
    
    homepage = {
      name = mkOpt str "Lidarr" "Name shown on homepage";
      description = mkOpt str "Music collection manager" "Description shown on homepage";
      icon = mkOpt str "lidarr.svg" "Icon shown on homepage";
      category = mkOpt str "Arr" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.lidarr = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8686
      '';
    };
  };
}
