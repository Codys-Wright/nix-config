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
  cfg = config.${namespace}.services.selfhost.cloud.ocis;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.cloud.ocis = with types; {
    enable = mkBoolOpt false "Enable OCIS (ownCloud Infinite Scale)";
    
    configDir = mkOpt str "/var/lib/ocis" "Configuration directory for OCIS";
    
    url = mkOpt str "cloud.${selfhostCfg.baseDomain}" "URL for OCIS service";
    
    cloudflared = {
      credentialsFile = mkOpt str "" "Cloudflare tunnel credentials file";
      tunnelId = mkOpt str "" "Cloudflare tunnel ID";
    };
    
    homepage = {
      name = mkOpt str "OCIS" "Name shown on homepage";
      description = mkOpt str "Enterprise File Storage and Collaboration" "Description shown on homepage";
      icon = mkOpt str "owncloud.svg" "Icon shown on homepage";
      category = mkOpt str "Cloud" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.ocis = {
      enable = true;
      url = "https://${cfg.url}";
      environment = {
        # Basic configuration - OIDC can be configured later
        PROXY_AUTOPROVISION_ACCOUNTS = "true";
        OCIS_LOG_LEVEL = "error";
        PROXY_TLS = "false";
        OCIS_INSECURE = "false";
        OCIS_EXCLUDE_RUN_SERVICES = "idp";
        # Optional OIDC integration with Keycloak
        # PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
        # OCIS_OIDC_ISSUER = "https://login.${selfhostCfg.baseDomain}/realms/master";
        # WEB_OIDC_CLIENT_ID = "ocis";
      };
    };

    # Initialize OCIS
    systemd.services.ocis.preStart = ''
      ${lib.getExe pkgs.ocis} init || true
    '';
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://${config.services.ocis.address}:${toString config.services.ocis.port}
      '';
    };
    
    # Optional Cloudflare tunnel
    services.cloudflared = mkIf (cfg.cloudflared.tunnelId != "" && cfg.cloudflared.credentialsFile != "") {
      enable = true;
      tunnels.${cfg.cloudflared.tunnelId} = {
        credentialsFile = cfg.cloudflared.credentialsFile;
        default = "http_status:404";
        ingress."${cfg.url}".service = "http://${config.services.ocis.address}:${toString config.services.ocis.port}";
      };
    };
  };
} 