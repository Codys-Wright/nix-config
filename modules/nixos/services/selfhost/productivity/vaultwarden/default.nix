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
  cfg = config.${namespace}.services.selfhost.productivity.vaultwarden;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.productivity.vaultwarden = with types; {
    enable = mkBoolOpt false "Enable Vaultwarden (password manager)";
    
    configDir = mkOpt str "/var/lib/bitwarden_rs" "Configuration directory for Vaultwarden";
    
    url = mkOpt str "pass.${selfhostCfg.baseDomain}" "URL for Vaultwarden service";
    
    cloudflared = {
      credentialsFile = mkOpt str "" "Cloudflare tunnel credentials file";
      tunnelId = mkOpt str "" "Cloudflare tunnel ID";
    };
    
    homepage = {
      name = mkOpt str "Vaultwarden" "Name shown on homepage";
      description = mkOpt str "Password manager" "Description shown on homepage";
      icon = mkOpt str "bitwarden.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://${cfg.url}";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        EXTENDED_LOGGING = true;
        LOG_LEVEL = "warn";
        IP_HEADER = "CF-Connecting-IP";
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8222
      '';
    };
    
    # Optional Cloudflare tunnel configuration
    services.cloudflared = mkIf (cfg.cloudflared.tunnelId != "" && cfg.cloudflared.credentialsFile != "") {
      enable = true;
      tunnels.${cfg.cloudflared.tunnelId} = {
        credentialsFile = cfg.cloudflared.credentialsFile;
        default = "http_status:404";
        ingress."${cfg.url}".service = "http://127.0.0.1:8222";
      };
    };
    
    # Optional fail2ban integration
    ${namespace}.services.selfhost.utility.fail2ban-cloudflare.jails.vaultwarden = mkIf cfg.cloudflared.fail2ban {
      serviceName = "vaultwarden";
      failRegex = "^.*Username or password is incorrect. Try again. IP: <HOST>. Username: <F-USER>.*</F-USER>.$";
    };
  };
} 