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
  cfg = config.${namespace}.services.selfhost.utility.uptime-kuma;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.utility.uptime-kuma = with types; {
    enable = mkBoolOpt false "Enable Uptime Kuma (service monitoring)";
    
    configDir = mkOpt str "/var/lib/uptime-kuma" "Configuration directory for Uptime Kuma";
    
    url = mkOpt str "uptime.${selfhostCfg.baseDomain}" "URL for Uptime Kuma service";
    
    homepage = {
      name = mkOpt str "Uptime Kuma" "Name shown on homepage";
      description = mkOpt str "Service monitoring tool" "Description shown on homepage";
      icon = mkOpt str "uptime-kuma.svg" "Icon shown on homepage";
      category = mkOpt str "Utility" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3001
      '';
    };
  };
} 