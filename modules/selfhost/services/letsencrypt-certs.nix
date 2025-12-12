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

      # The SOPS template will be created at this path
      credentialsFile = config.sops.templates."acme-cloudflare-credentials".path;
    in {
      # Let's Encrypt certificate configuration
      # This follows the selfhostblocks pattern directly
      shb.certs.certs.letsencrypt.${actualCertName} = {
        domain = domain; # Request cert for root domain
        extraDomains = ["*.${domain}"]; # Include wildcard for all subdomains
        group = "nginx";
        reloadServices = ["nginx.service"];
        dnsProvider = "cloudflare";
        adminEmail = adminEmail;
        credentialsFile = credentialsFile;
        # Optional: Enable debug logging during initial setup
        debug = lib.mkDefault false;
      };

      # SOPS secret for Cloudflare API token (just the raw token value)
      shb.sops.secret."${cloudflareTokenKey}" = {
        request = lib.mkDefault {};
        settings = {
          mode = "0400";
        };
      };

      # Create a sops-nix template file that formats the credentials correctly for ACME/lego
      # lego expects: CF_DNS_API_TOKEN=token_value
      # This uses sops-nix's built-in template feature to create the formatted file
      sops.templates."acme-cloudflare-credentials" = {
        content = ''
          CF_DNS_API_TOKEN=${config.sops.placeholder."${cloudflareTokenKey}"}
        '';
        mode = "0400";
        owner = "acme";
        group = "acme";
      };

      # Disable systemd-resolved to avoid DNS conflicts during ACME challenge
      services.resolved.enable = lib.mkForce false;
    };
  };
}
