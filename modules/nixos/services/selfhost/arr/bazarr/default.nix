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
  cfg = config.${namespace}.services.selfhost.arr.bazarr;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.arr.bazarr = with types; {
    enable = mkBoolOpt false "Enable Bazarr (subtitle manager)";
    
    configDir = mkOpt str "/var/lib/bazarr" "Configuration directory for Bazarr";
    
    url = mkOpt str "bazarr.${selfhostCfg.baseDomain}" "URL for Bazarr service";
    
    homepage = {
      name = mkOpt str "Bazarr" "Name shown on homepage";
      description = mkOpt str "Subtitle manager" "Description shown on homepage";
      icon = mkOpt str "bazarr.svg" "Icon shown on homepage";
      category = mkOpt str "Arr" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString config.services.bazarr.listenPort}
      '';
    };
  };
}
