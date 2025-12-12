# Cloudflare Tunnel aspect for exposing services without port forwarding
{
  FTS,
  lib,
  __findFile,
  ...
}: {
  # Cloudflare Tunnel aspect
  # Usage: FTS.selfhost._.cloudflare-tunnel { tunnelId = "uuid"; ... }
  FTS.selfhost._.cloudflare-tunnel = {
    tunnelId,
    credentialsFile,
    domain,
    # Optional parameters
    excludeJDownloader ? true,
    defaultService ? "http_status:404",
    noTLSVerify ? true,
    autoRouteDNS ? true,
    ...
  } @ args: {
    class,
    aspect-chain,
    ...
  }: {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Ensure cloudflared is available
      environment.systemPackages = [pkgs.cloudflared];

      # Extract nginx virtual hosts and create ingress rules
      services.cloudflared = lib.mkIf (tunnelId != "") {
        enable = true;
        tunnels."${tunnelId}" = {
          default = defaultService;

          # Dynamically generate ingress rules from nginx config
          ingress = let
            # Get all nginx virtual hosts configured by SelfHostBlocks
            nginxHosts = lib.attrNames config.services.nginx.virtualHosts;

            # Clean domain names (remove http:// or https:// prefix)
            cleanDomain = host:
              if lib.hasPrefix "http://" host
              then lib.removePrefix "http://" host
              else if lib.hasPrefix "https://" host
              then lib.removePrefix "https://" host
              else host;

            # Extract upstream from nginx config
            getDestination = domain: let
              virtualHost = config.services.nginx.virtualHosts.${domain} or {};
              locations = virtualHost.locations or {};
              # Get the root location's proxy_pass
              rootLocation = locations."/" or {};
              proxyPass = rootLocation.proxyPass or "http://localhost";
            in
              proxyPass;

            # Check if domain should be excluded
            shouldExclude = domain:
              excludeJDownloader
              && lib.hasInfix "jdownloader" (lib.toLower domain);

            # Build ingress rules
            buildRules =
              lib.foldl' (
                acc: host: let
                  cleanedDomain = cleanDomain host;
                  destination = getDestination host;
                in
                  if shouldExclude cleanedDomain
                  then acc
                  else acc // {"${cleanedDomain}" = destination;}
              ) {}
              nginxHosts;
          in
            buildRules;

          originRequest = lib.mkIf noTLSVerify {
            noTLSVerify = true;
          };

          credentialsFile = credentialsFile;
        };
      };

      # Optional: Auto-route DNS for all domains
      systemd.services."cloudflared-dns-route-${tunnelId}" = lib.mkIf (tunnelId != "" && autoRouteDNS) {
        description = "Cloudflare Tunnel DNS Route for ${domain}";
        after = ["network-online.target" "cloudflared-tunnel-${tunnelId}.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = let
            nginxHosts = lib.attrNames config.services.nginx.virtualHosts;
            cleanDomain = host:
              if lib.hasPrefix "http://" host
              then lib.removePrefix "http://" host
              else if lib.hasPrefix "https://" host
              then lib.removePrefix "https://" host
              else host;
            domainNames = map cleanDomain nginxHosts;

            routeCommands = lib.concatStringsSep "\n" (map (d: ''
                echo "Routing ${d} to tunnel ${tunnelId}..."
                ${pkgs.cloudflared}/bin/cloudflared tunnel route dns "${tunnelId}" "${d}" || true
              '')
              domainNames);
          in
            pkgs.writeShellScript "route-dns" ''
              #!/bin/bash
              set -e
              echo "Routing DNS for Cloudflare tunnel ${tunnelId}..."
              ${routeCommands}
              echo "DNS routing complete!"
            '';

          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };
    };
  };
}
