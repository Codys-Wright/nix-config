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
  cfg = config.${namespace}.services.selfhost.arr.jellyseerr;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.arr.jellyseerr = with types; {
    enable = mkBoolOpt false "Enable Jellyseerr (media request and discovery manager)";
    
    url = mkOpt str "jellyseerr.${selfhostCfg.baseDomain}" "URL for Jellyseerr service";
    
    port = mkOpt port 5055 "Port for Jellyseerr service";
    
    package = mkOpt types.package pkgs.jellyseerr "Jellyseerr package to use";
    
    homepage = {
      name = mkOpt str "Jellyseerr" "Name shown on homepage";
      description = mkOpt str "Media request and discovery manager" "Description shown on homepage";
      icon = mkOpt str "jellyseerr.svg" "Icon shown on homepage";
      category = mkOpt str "Arr" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.jellyseerr = {
      enable = true;
      port = cfg.port;
      package = cfg.package;
    };
    
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
