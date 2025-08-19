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
  cfg = config.${namespace}.services.selfhost.downloads.sabnzbd;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.downloads.sabnzbd = with types; {
    enable = mkBoolOpt false "Enable SABnzbd (usenet downloader)";
    
    configDir = mkOpt str "/var/lib/sabnzbd" "Configuration directory for SABnzbd";
    
    url = mkOpt str "sabnzbd.${selfhostCfg.baseDomain}" "URL for SABnzbd service";
    
    homepage = {
      name = mkOpt str "SABnzbd" "Name shown on homepage";
      description = mkOpt str "The free and easy binary newsreader" "Description shown on homepage";
      icon = mkOpt str "sabnzbd.svg" "Icon shown on homepage";
      category = mkOpt str "Downloads" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.sabnzbd = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8080
      '';
    };
  };
} 