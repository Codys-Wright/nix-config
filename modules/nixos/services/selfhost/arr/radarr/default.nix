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
  cfg = config.${namespace}.services.selfhost.arr.radarr;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.arr.radarr = with types; {
    enable = mkBoolOpt false "Enable Radarr (movie collection manager)";
    
    configDir = mkOpt str "/var/lib/radarr" "Configuration directory for Radarr";
    
    url = mkOpt str "radarr.${selfhostCfg.baseDomain}" "URL for Radarr service";
    
    homepage = {
      name = mkOpt str "Radarr" "Name shown on homepage";
      description = mkOpt str "Movie collection manager" "Description shown on homepage";
      icon = mkOpt str "radarr.svg" "Icon shown on homepage";
      category = mkOpt str "Arr" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.radarr = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:7878
      '';
    };
  };
}
