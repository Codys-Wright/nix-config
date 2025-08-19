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
  cfg = config.${namespace}.services.selfhost.arr.prowlarr;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.arr.prowlarr = with types; {
    enable = mkBoolOpt false "Enable Prowlarr (PVR indexer)";
    
    configDir = mkOpt str "/var/lib/prowlarr" "Configuration directory for Prowlarr";
    
    url = mkOpt str "prowlarr.${selfhostCfg.baseDomain}" "URL for Prowlarr service";
    
    homepage = {
      name = mkOpt str "Prowlarr" "Name shown on homepage";
      description = mkOpt str "PVR indexer" "Description shown on homepage";
      icon = mkOpt str "prowlarr.svg" "Icon shown on homepage";
      category = mkOpt str "Arr" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
    };
    
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9696
      '';
    };
  };
}
