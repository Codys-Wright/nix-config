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
  cfg = config.${namespace}.services.selfhost.networking.cloudflare-tunnel;
in
{
  options.${namespace}.services.selfhost.networking.cloudflare-tunnel = with types; {
    enable = mkBoolOpt false "Enable Cloudflare Tunnel";
    
    tunnelId = mkOpt str "" "Cloudflare tunnel ID (UUID)";
    
    credentialsFile = mkOpt (nullOr path) null "Path to tunnel credentials JSON file";
    
    ingress = mkOpt (attrsOf (either str attrs)) {} "Ingress rules mapping domains to local services";
    
    default = mkOpt str "http_status:404" "Default response for unmatched requests";
    
    homepage = {
      name = mkOpt str "Cloudflare Tunnel" "Name shown on homepage";
      description = mkOpt str "Secure tunnel to expose services without port forwarding" "Description shown on homepage";
      icon = mkOpt str "cloudflare.svg" "Icon shown on homepage";
      category = mkOpt str "Networking" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Use the standard NixOS cloudflared module
    services.cloudflared = {
      enable = true;
      tunnels = mkIf (cfg.tunnelId != "" && cfg.credentialsFile != null) {
        "${cfg.tunnelId}" = {
          credentialsFile = cfg.credentialsFile;
          default = cfg.default;
          ingress = cfg.ingress;
        };
      };
    };

    # TODO: Add homepage integration when homepage module is available
  };
} 