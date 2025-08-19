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
  cfg = config.${namespace}.services.selfhost.utility.keycloak;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.utility.keycloak = with types; {
    enable = mkBoolOpt false "Enable Keycloak (identity and access management)";
    
    url = mkOpt str "login.${selfhostCfg.baseDomain}" "URL for Keycloak service";
    
    dbPasswordFile = mkOpt path "" "File containing database password";
    
    cloudflared = {
      credentialsFile = mkOpt str "" "Cloudflare tunnel credentials file";
      tunnelId = mkOpt str "" "Cloudflare tunnel ID";
    };
    
    homepage = {
      name = mkOpt str "Keycloak" "Name shown on homepage";
      description = mkOpt str "Open Source Identity and Access Management" "Description shown on homepage";
      icon = mkOpt str "keycloak.svg" "Icon shown on homepage";
      category = mkOpt str "Utility" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.keycloak = {
      enable = true;
      # Basic configuration - can be expanded with database, themes, etc.
      # The original has extensive PostgreSQL and theme configuration
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8080
      '';
    };
    
    # Optional Cloudflare tunnel
    services.cloudflared = mkIf (cfg.cloudflared.tunnelId != "" && cfg.cloudflared.credentialsFile != "") {
      enable = true;
      tunnels.${cfg.cloudflared.tunnelId} = {
        credentialsFile = cfg.cloudflared.credentialsFile;
        default = "http_status:404";
        ingress."${cfg.url}".service = "http://127.0.0.1:8080";
      };
    };
    
    # TODO: Add PostgreSQL database configuration
    # TODO: Add custom theme support
    # The original has extensive customization
  };
} 