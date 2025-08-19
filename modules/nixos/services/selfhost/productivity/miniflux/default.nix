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
  cfg = config.${namespace}.services.selfhost.productivity.miniflux;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.productivity.miniflux = with types; {
    enable = mkBoolOpt false "Enable Miniflux (RSS reader)";
    
    configDir = mkOpt str "/var/lib/miniflux" "Configuration directory for Miniflux";
    
    url = mkOpt str "news.${selfhostCfg.baseDomain}" "URL for Miniflux service";
    
    adminCredentialsFile = mkOpt path "" "File containing admin credentials";
    
    cloudflared = {
      credentialsFile = mkOpt str "" "Cloudflare tunnel credentials file";
      tunnelId = mkOpt str "" "Cloudflare tunnel ID";
    };
    
    homepage = {
      name = mkOpt str "Miniflux" "Name shown on homepage";
      description = mkOpt str "Minimalist and opinionated feed reader" "Description shown on homepage";
      icon = mkOpt str "miniflux-light.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.miniflux = {
      enable = true;
      adminCredentialsFile = cfg.adminCredentialsFile;
      config = {
        BASE_URL = "https://${cfg.url}";
        CREATE_ADMIN = "1";
        LISTEN_ADDR = "127.0.0.1:8067";
        # Optional OIDC integration - can be configured later
        # OAUTH2_PROVIDER = "oidc";
        # OAUTH2_CLIENT_ID = "miniflux";
        # OAUTH2_REDIRECT_URL = "https://${cfg.url}/oauth2/oidc/callback";
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8067
      '';
    };
    
    # Optional Cloudflare tunnel
    services.cloudflared = mkIf (cfg.cloudflared.tunnelId != "" && cfg.cloudflared.credentialsFile != "") {
      enable = true;
      tunnels.${cfg.cloudflared.tunnelId} = {
        credentialsFile = cfg.cloudflared.credentialsFile;
        default = "http_status:404";
        ingress."${cfg.url}".service = "http://127.0.0.1:8067";
      };
    };
  };
} 