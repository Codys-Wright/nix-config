# Cloudflare Tunnel aspect for exposing services without port forwarding
{
  FTS,
  lib,
  __findFile,
  ...
}: {
  # Cloudflare Tunnel aspect
  # Usage: FTS.selfhost._.cloudflare-tunnel { domain = "example.com"; ... }
  FTS.selfhost._.cloudflare-tunnel = {
    tunnelId,
    domain,
    # SOPS secret keys for tunnel credentials
    accountTagKey ? "starcommand/selfhost/proxy/cloudflare/account_tag",
    tunnelSecretKey ? "starcommand/selfhost/proxy/cloudflare/starcommand_tunnel/secret",
    dnsApiTokenKey ? "starcommand/selfhost/proxy/cloudflare/zone_dns_key",
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
    }: let
      # Extract all nginx virtual hosts and clean domain names
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
        rootLocation = locations."/" or {};

        # Try proxyPass attribute first
        proxyPassAttr = rootLocation.proxyPass or null;

        # If not found, try to extract from extraConfig
        extraConfig = rootLocation.extraConfig or "";
        proxyPassMatch = builtins.match ".*proxy_pass ([^;]+);.*" extraConfig;
        proxyPassFromConfig =
          if proxyPassMatch != null
          then builtins.head proxyPassMatch
          else null;

        # Use whichever we found
        rawProxyPass =
          if proxyPassAttr != null
          then proxyPassAttr
          else proxyPassFromConfig;

        # Strip trailing slash if present (cloudflared doesn't like paths)
        proxyPass =
          if rawProxyPass != null && lib.hasSuffix "/" rawProxyPass
          then lib.removeSuffix "/" rawProxyPass
          else rawProxyPass;
      in
        proxyPass;

      # Check if domain should be excluded
      shouldExclude = domain:
        excludeJDownloader && lib.hasInfix "jdownloader" (lib.toLower domain);

      # Build ingress rules as an array
      buildRules =
        lib.foldl' (
          acc: host: let
            cleanedDomain = cleanDomain host;
            destination = getDestination host;
          in
            # Skip if excluded or if destination is null/invalid
            if shouldExclude cleanedDomain || destination == null
            then acc
            else
              acc
              ++ [
                {
                  hostname = cleanedDomain;
                  service = destination;
                }
              ]
        ) []
        nginxHosts;

      # Create cloudflared config
      tunnelConfig = {
        tunnel = tunnelId;
        credentials-file = "/var/lib/cloudflared/${tunnelId}.json";
        originRequest = lib.optionalAttrs noTLSVerify {
          noTLSVerify = true;
        };
        ingress =
          buildRules
          ++ [
            {service = defaultService;}
          ];
      };

      configYaml = pkgs.writeText "cloudflared-config.yml" (builtins.toJSON tunnelConfig);
    in {
      # Ensure cloudflared is available
      environment.systemPackages = [pkgs.cloudflared];

      # SOPS secrets for Cloudflare tunnel
      # Secrets owned by root, readable by owner only
      # The systemd service will read them and generate the credentials file
      shb.sops.secret."${accountTagKey}" = {
        request = lib.mkDefault {};
        settings.mode = "0400";
      };
      shb.sops.secret."${tunnelSecretKey}" = {
        request = lib.mkDefault {};
        settings.mode = "0400";
      };
      shb.sops.secret."${dnsApiTokenKey}" = lib.mkIf autoRouteDNS {
        request = lib.mkDefault {};
        settings.mode = "0400";
      };

      # Create /var/lib/cloudflared directory
      systemd.tmpfiles.rules = [
        "d /var/lib/cloudflared 0755 root root -"
      ];

      # Generate credentials file from SOPS secrets
      systemd.services."cloudflared-credentials-${tunnelId}" = {
        description = "Generate Cloudflare Tunnel credentials for ${tunnelId}";
        wantedBy = ["multi-user.target"];
        before = ["cloudflared-tunnel-${tunnelId}.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          cat > /var/lib/cloudflared/${tunnelId}.json <<EOF
          {
            "AccountTag": "$(cat ${config.shb.sops.secret."${accountTagKey}".result.path})",
            "TunnelSecret": "$(cat ${config.shb.sops.secret."${tunnelSecretKey}".result.path})",
            "TunnelID": "${tunnelId}",
            "Endpoint": ""
          }
          EOF
          chmod 600 /var/lib/cloudflared/${tunnelId}.json
        '';
      };

      # Cloudflared tunnel service
      systemd.services."cloudflared-tunnel-${tunnelId}" = {
        description = "Cloudflare Tunnel ${tunnelId}";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target" "cloudflared-credentials-${tunnelId}.service"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        script = ''
          exec ${pkgs.cloudflared}/bin/cloudflared tunnel \
            --no-autoupdate \
            --config ${configYaml} \
            run "${tunnelId}"
        '';
      };

      # Optional: Auto-route DNS for all domains using Cloudflare API
      systemd.services."cloudflared-dns-route-${tunnelId}" = lib.mkIf autoRouteDNS {
        description = "Cloudflare Tunnel DNS Route for ${domain}";
        after = ["network-online.target" "cloudflared-tunnel-${tunnelId}.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.curl pkgs.jq];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "30s";
        };
        script = let
          domainNames = map cleanDomain nginxHosts;
          # Filter out localhost
          validDomains = builtins.filter (d: d != "localhost") domainNames;
          routeCommands = lib.concatStringsSep "\n" (map (d: ''
              echo "Setting DNS for ${d} to tunnel ${tunnelId}..."
              # Get zone ID for the domain
              ZONE_ID=$(${pkgs.curl}/bin/curl -s -X GET \
                "https://api.cloudflare.com/client/v4/zones?name=${domain}" \
                -H "Authorization: Bearer $(cat ${config.shb.sops.secret."${dnsApiTokenKey}".result.path})" \
                -H "Content-Type: application/json" | ${pkgs.jq}/bin/jq -r '.result[0].id')

              if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
                echo "ERROR: Could not find zone ID for ${domain}"
                exit 1
              fi

              # Check if DNS record already exists
              RECORD_ID=$(${pkgs.curl}/bin/curl -s -X GET \
                "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=${d}&type=CNAME" \
                -H "Authorization: Bearer $(cat ${config.shb.sops.secret."${dnsApiTokenKey}".result.path})" \
                -H "Content-Type: application/json" | ${pkgs.jq}/bin/jq -r '.result[0].id // empty')

              if [ -n "$RECORD_ID" ]; then
                echo "✓ DNS record for ${d} already exists (ID: $RECORD_ID)"
              else
                # Create CNAME record pointing to tunnel
                ${pkgs.curl}/bin/curl -s -X POST \
                  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
                  -H "Authorization: Bearer $(cat ${config.shb.sops.secret."${dnsApiTokenKey}".result.path})" \
                  -H "Content-Type: application/json" \
                  --data "{\"type\":\"CNAME\",\"name\":\"${d}\",\"content\":\"${tunnelId}.cfargotunnel.com\",\"ttl\":1,\"proxied\":true}" \
                  > /dev/null
                echo "✓ Created DNS record for ${d}"
              fi
            '')
            validDomains);
        in ''
          echo "Configuring DNS for Cloudflare tunnel ${tunnelId}..."
          ${routeCommands}
          echo "DNS configuration complete!"
        '';
      };
    };
  };
}
