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
  selfhostCfg = config.${namespace}.services.selfhost;

  # Extract all Caddy virtual hosts and clean domain names
  caddyHosts = lib.attrNames config.services.caddy.virtualHosts;
  domainNames = map (host:
    if lib.hasPrefix "http://" host then lib.removePrefix "http://" host
    else if lib.hasPrefix "https://" host then lib.removePrefix "https://" host
    else host
  ) caddyHosts;

  # Create ingress rules from Caddy virtual hosts
  # Extract reverse_proxy destinations and map to domains
  ingressRules = lib.foldl' (acc: domain:
    let
      virtualHost = config.services.caddy.virtualHosts.${domain} or {};
      extraConfig = virtualHost.extraConfig or "";
      # Extract reverse_proxy destination from extraConfig
      reverseProxyMatch = builtins.match ".*reverse_proxy ([^\n]+).*" extraConfig;
      rawDestination = if reverseProxyMatch != null then builtins.head reverseProxyMatch else "http://localhost";
      # Replace 127.0.0.1 with localhost for cleaner configuration
      destination = builtins.replaceStrings ["127.0.0.1"] ["localhost"] rawDestination;
    in
    acc // {
      "${domain}" = destination;
    }
  ) {} domainNames;

  # Create a script to route DNS for all domains
  dnsRouteScript = pkgs.writeShellScript "cloudflare-dns-route" ''
    #!/bin/bash
    set -e

    TUNNEL_ID="${cfg.tunnelId}"

    echo "Routing DNS for Cloudflare tunnel $TUNNEL_ID..."

    ${concatStringsSep "\n" (map (domain: ''
      echo "Routing ${domain} to tunnel $TUNNEL_ID..."
      ${pkgs.cloudflared}/bin/cloudflared tunnel route dns "$TUNNEL_ID" "${domain}"
      echo "✓ Successfully routed ${domain}"
    '') domainNames)}

    echo "DNS routing complete for all domains!"
  '';
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

environment.systemPackages = [
    pkgs.cloudflared
  ];

 services.cloudflared = mkIf (cfg.tunnelId != "") {
      enable = true;
      tunnels = {
        "${cfg.tunnelId}" = {
          default = "http_status:404";
          ingress = ingressRules;
          originRequest = {
            noTLSVerify = true;
          };
          credentialsFile = "/home/cody/.cloudflared/${cfg.tunnelId}.json";
        };
      };
    };

    # Systemd service to route DNS for all subdomains to the tunnel
    systemd.services."cloudflared-dns-route-${cfg.tunnelId}" = mkIf (cfg.tunnelId != "") {
      description = "Cloudflare Tunnel DNS Route for ${selfhostCfg.baseDomain}";
      after = [ "network-online.target" "cloudflared-tunnel-${cfg.tunnelId}.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "cody";
        Group = "users";
        ExecStart = "${dnsRouteScript}";
        # Only run once per boot
        RemainAfterExit = true;
        # Retry on failure
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    # TODO: Add homepage integration when homepage module is available
  };
} 