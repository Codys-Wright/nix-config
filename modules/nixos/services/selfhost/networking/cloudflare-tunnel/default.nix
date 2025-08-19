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
in
{
  options.${namespace}.services.selfhost.networking.cloudflare-tunnel = with types; {
    enable = mkBoolOpt false "Enable Cloudflare Tunnel";
    
    tunnelId = mkOpt str "" "Cloudflare tunnel UUID";
    
    tunnelToken = mkOpt str "" "Cloudflare tunnel token (from dashboard)";
    
    credentialsFile = mkOpt (nullOr path) null "Path to tunnel credentials JSON file (alternative to token)";
    
    ingress = mkOpt (attrsOf str) {} "Ingress rules mapping domains to local services";
    
    homepage = {
      name = mkOpt str "Cloudflare Tunnel" "Name shown on homepage";
      description = mkOpt str "Secure tunnel to expose services without port forwarding" "Description shown on homepage";
      icon = mkOpt str "cloudflare.svg" "Icon shown on homepage";
      category = mkOpt str "Networking" "Category on homepage";
    };
  };

    config = mkIf cfg.enable {
    # Install cloudflared package
    environment.systemPackages = [
      pkgs.cloudflared
    ];

    # Use the standard NixOS cloudflared module
    services.cloudflared = mkIf (cfg.tunnelToken != "" || cfg.credentialsFile != null) {
      enable = true;
      tunnels = mkMerge [
        # Token-based configuration using provided tunnel ID
        (mkIf (cfg.tunnelToken != "" && cfg.tunnelId != "") {
          "${cfg.tunnelId}" = {
            credentialsFile = "/var/lib/cloudflared/tunnel-credentials.json";
            default = "http_status:404";
            ingress = cfg.ingress;
            originRequest = {
              noTLSVerify = false;
              connectTimeout = "30s";
              tlsTimeout = "10s";
              tcpKeepAlive = "30s";
              keepAliveConnections = 100;
              keepAliveTimeout = "1m30s";
            };
          };
        })
        
        # Direct credentials file configuration
        (mkIf (cfg.credentialsFile != null) {
          "${cfg.tunnelId}" = {
            credentialsFile = cfg.credentialsFile;
            default = "http_status:404";
            ingress = cfg.ingress;
            originRequest = {
              noTLSVerify = false;
              connectTimeout = "30s";
              tlsTimeout = "10s";
              tcpKeepAlive = "30s";
              keepAliveConnections = 100;
              keepAliveTimeout = "1m30s";
            };
          };
        })
      ];
    };

    # Create cloudflared user and group (needed before the service runs)
    users.users.cloudflared = mkIf (cfg.tunnelToken != "" || cfg.credentialsFile != null) {
      isSystemUser = true;
      group = "cloudflared";
      home = "/var/lib/cloudflared";
      createHome = true;
    };
    
    users.groups.cloudflared = mkIf (cfg.tunnelToken != "" || cfg.credentialsFile != null) {};

    # Create credentials file from token
    systemd.tmpfiles.rules = mkIf (cfg.tunnelToken != "") [
      "d /var/lib/cloudflared 0755 cloudflared cloudflared - -"
    ];

    # Setup service to create credentials file from token
    systemd.services.cloudflared-credentials-setup = mkIf (cfg.tunnelToken != "") {
      description = "Setup Cloudflare Tunnel Credentials from Token";
      before = [ "cloudflared.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "cloudflared";
        Group = "cloudflared";
      };
      
      script = ''
        # The token is a base64-encoded JSON credentials file
        # Decode it and rename the fields to the expected format
        TOKEN="${cfg.tunnelToken}"
        
        # Decode the base64 token to get the original JSON
        DECODED=$(echo "$TOKEN" | ${pkgs.coreutils}/bin/base64 -d)
        
        # Extract the values and create properly formatted credentials file
        ACCOUNT_TAG=$(echo "$DECODED" | ${pkgs.jq}/bin/jq -r '.a')
        TUNNEL_ID=$(echo "$DECODED" | ${pkgs.jq}/bin/jq -r '.t')  
        TUNNEL_SECRET=$(echo "$DECODED" | ${pkgs.jq}/bin/jq -r '.s')
        
        # Create the credentials file with the exact format cloudflared expects
        ${pkgs.jq}/bin/jq -n \
          --arg account "$ACCOUNT_TAG" \
          --arg tunnel "$TUNNEL_ID" \
          --arg secret "$TUNNEL_SECRET" \
          '{
            "AccountTag": $account,
            "TunnelID": $tunnel,
            "TunnelSecret": $secret
          }' > /var/lib/cloudflared/tunnel-credentials.json
        
        chmod 600 /var/lib/cloudflared/tunnel-credentials.json
        chown cloudflared:cloudflared /var/lib/cloudflared/tunnel-credentials.json
      '';
    };

    # Firewall configuration (allow outbound connections to Cloudflare)
    networking.firewall = {
      allowedTCPPorts = [ ]; # No inbound ports needed!
      allowedUDPPorts = [ ]; # Tunnel handles everything
    };
  };
} 