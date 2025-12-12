# Let's Encrypt Certificates with Cloudflare DNS
# Production-ready SSL certificates using Let's Encrypt and Cloudflare DNS challenge
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.letsencrypt-certs = {
    domain,
    subdomains ? [],
    certName ? null, # Will default to domain if not specified
    adminEmail,
    cloudflareTokenKey,
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      Let's Encrypt certificates - Production SSL certificates using Cloudflare DNS validation.

      Provides wildcard certificates from Let's Encrypt using Cloudflare DNS challenge.
      Certificates are automatically renewed and trusted by all browsers.
    '';

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      # Use domain as certName if not explicitly specified
      actualCertName =
        if certName != null
        then certName
        else domain;
    in {
      # Create a properly formatted credentials file for ACME/lego
      # lego expects: CF_DNS_API_TOKEN=token_value
      systemd.services."cloudflare-credentials-wrapper" = {
        description = "Create Cloudflare credentials file for ACME";
        wantedBy = ["multi-user.target"];
        before = ["acme-${actualCertName}.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          mkdir -p /var/lib/secrets/acme
          echo "CF_DNS_API_TOKEN=$(cat ${config.shb.sops.secret."${cloudflareTokenKey}".result.path})" > /var/lib/secrets/acme/cloudflare-credentials
          chmod 0400 /var/lib/secrets/acme/cloudflare-credentials
        '';
      };

      # Let's Encrypt certificate configuration
      shb.certs.certs.letsencrypt.${actualCertName} = {
        domain = domain; # Request cert for root domain
        extraDomains = ["*.${domain}"]; # Include wildcard for all subdomains
        group = "nginx";
        reloadServices = ["nginx.service"];
        dnsProvider = "cloudflare";
        adminEmail = adminEmail;
        credentialsFile = "/var/lib/secrets/acme/cloudflare-credentials";
      };

      # SOPS secret for Cloudflare API token
      shb.sops.secret."${cloudflareTokenKey}" = {
        request = lib.mkDefault {};
        settings.mode = "0400";
      };

      # Disable systemd-resolved to avoid conflicts
      services.resolved.enable = lib.mkForce false;
    };
  };
}
