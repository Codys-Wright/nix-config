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
  cfg = config.${namespace}.services.selfhost.productivity.radicale;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.productivity.radicale = with types; {
    enable = mkBoolOpt false "Enable Radicale (CalDAV/CardDAV server)";
    
    url = mkOpt str "cal.${selfhostCfg.baseDomain}" "URL for Radicale service";
    
    homepage = {
      name = mkOpt str "Radicale" "Name shown on homepage";
      description = mkOpt str "CalDAV and CardDAV server" "Description shown on homepage";
      icon = mkOpt str "radicale.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.radicale = {
      enable = true;
      settings = {
        server = {
          hosts = [ "127.0.0.1:5232" ];
        };
        auth = {
          type = "htpasswd";
          htpasswd_filename = "/var/lib/radicale/users";
          htpasswd_encryption = "bcrypt";
        };
        storage = {
          filesystem_folder = "/var/lib/radicale/collections";
        };
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:5232
      '';
    };
  };
} 