# Local Certificates Service
# Self-signed SSL certificates with local DNS resolution
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.local-certs = {
    domain,
    subdomains ? [],
    caName ? "Starcommand CA",
    certName ? "starcommand",
    # Optional parameters
    enableDnsmasq ? true,
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      Local certificates - Self-signed SSL certificates with dnsmasq.

      Provides self-signed wildcard certificates and local DNS resolution.
      Useful for development and local testing.
    '';

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Self-signed SSL certificates
      shb.certs = {
        cas.selfsigned.myca = {
          name = caName;
        };
        certs.selfsigned.${certName} = {
          ca = config.shb.certs.cas.selfsigned.myca;
          domain = "*.${domain}";
          group = "nginx";
        };
      };

      # Local DNS resolution with dnsmasq
      services.dnsmasq = lib.mkIf enableDnsmasq {
        enable = true;
        settings = {
          domain-needed = true;
          bogus-priv = true;
          # Map all subdomains to localhost
          address = map (hostname: "/${hostname}/127.0.0.1") (
            [domain] ++ (map (sub: "${sub}.${domain}") subdomains)
          );
        };
      };

      # Disable systemd-resolved which conflicts with dnsmasq
      services.resolved.enable = lib.mkIf enableDnsmasq false;
    };
  };
}
