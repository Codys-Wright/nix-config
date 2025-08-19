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
  cfg = config.${namespace}.services.selfhost.utility.microbin;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.utility.microbin = with types; {
    enable = mkBoolOpt false "Enable Microbin (pastebin service)";
    
    configDir = mkOpt str "/var/lib/microbin" "Configuration directory for Microbin";
    
    url = mkOpt str "bin.${selfhostCfg.baseDomain}" "URL for Microbin service";
    
    passwordFile = mkOpt str "" "File containing admin credentials";
    
    cloudflared = {
      credentialsFile = mkOpt str "" "Cloudflare tunnel credentials file";
      tunnelId = mkOpt str "" "Cloudflare tunnel ID";
    };
    
    homepage = {
      name = mkOpt str "Microbin" "Name shown on homepage";
      description = mkOpt str "A minimal pastebin" "Description shown on homepage";
      icon = mkOpt str "microbin.png" "Icon shown on homepage";
      category = mkOpt str "Utility" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.microbin = {
      enable = true;
      settings = {
        MICROBIN_WIDE = true;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
        MICROBIN_PUBLIC_PATH = "https://${cfg.url}/";
        MICROBIN_BIND = "127.0.0.1";
        MICROBIN_PORT = 8069;
        MICROBIN_HIDE_LOGO = true;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_HIDE_HEADER = true;
        MICROBIN_HIDE_FOOTER = true;
      };
    } // optionalAttrs (cfg.passwordFile != "") {
      passwordFile = cfg.passwordFile;
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8069
      '';
    };
    
    # Optional Cloudflare tunnel
    services.cloudflared = mkIf (cfg.cloudflared.tunnelId != "" && cfg.cloudflared.credentialsFile != "") {
      enable = true;
      tunnels.${cfg.cloudflared.tunnelId} = {
        credentialsFile = cfg.cloudflared.credentialsFile;
        default = "http_status:404";
        ingress."${cfg.url}".service = "http://127.0.0.1:8069";
      };
    };
  };
} 