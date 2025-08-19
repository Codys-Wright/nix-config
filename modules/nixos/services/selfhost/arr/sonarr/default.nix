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
  cfg = config.${namespace}.services.selfhost.arr.sonarr;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.arr.sonarr = with types; {
    enable = mkBoolOpt false "Enable Sonarr (TV show collection manager)";
    
    configDir = mkOpt str "/var/lib/sonarr" "Configuration directory for Sonarr";
    
    url = mkOpt str "sonarr.${selfhostCfg.baseDomain}" "URL for Sonarr service";
    
    homepage = {
      name = mkOpt str "Sonarr" "Name shown on homepage";
      description = mkOpt str "TV show collection manager" "Description shown on homepage";
      icon = mkOpt str "sonarr.svg" "Icon shown on homepage";
      category = mkOpt str "Arr" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8989
      '';
    };
  };
}
