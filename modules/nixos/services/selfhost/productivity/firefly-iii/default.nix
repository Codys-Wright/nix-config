{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.selfhost.productivity.firefly-iii;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.productivity.firefly-iii = with types; {
    enable = mkBoolOpt false "Enable Firefly III (personal finance)";
    
    url = mkOpt str "finance.${selfhostCfg.baseDomain}" "URL for Firefly III service";
    
    dataDir = mkOpt str "/var/lib/firefly-iii" "Data directory for Firefly III";
    
    homepage = {
      name = mkOpt str "Firefly III" "Name shown on homepage";
      description = mkOpt str "Personal finance management" "Description shown on homepage";
      icon = mkOpt str "firefly.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Optional SOPS secrets for app key
    sops.secrets.firefly-key = mkIf (config.sops.secrets ? firefly-key) {
      owner = "firefly-iii";
    };

    services.firefly-iii = {
      enable = true;
      settings = {
        APP_ENV = "production";
        APP_KEY_FILE = if (config.sops.secrets ? firefly-key) then config.sops.secrets.firefly-key.path else "/dev/null";
        APP_URL = "https://${cfg.url}";
        
        DB_CONNECTION = "sqlite";
        
        TZ = selfhostCfg.timeZone;
        TRUSTED_PROXIES = "*";
        
        # Security settings
        FIREFLY_III_LAYOUT = "v1";
        SEND_REGISTRATION_MAIL = "true";
        SEND_ERROR_MESSAGE = "true";
      };
      
      enableNginx = true;
      virtualHost = cfg.url;
      dataDir = cfg.dataDir;
    };

    # Configure nginx to listen on localhost only
    services.nginx.virtualHosts.${cfg.url} = {
      enableACME = false;
      listen = [
        {
          addr = "127.0.0.1";
          port = 9080;
        }
      ];
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9080
      '';
    };
  };
}
