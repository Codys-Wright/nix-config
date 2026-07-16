# Core infrastructure stack: certificates + Cloudflare tunnel
{
  fleet,
  ...
}:
let
  inherit (import ../_data/vars.nix) domain;
in
{
  fleet.selfhost._.stack-core = {
    description = "Core selfhost infrastructure: Let's Encrypt certificates and Cloudflare tunnel";

    includes = [
      # Let's Encrypt certificates with Cloudflare DNS
      (fleet.selfhost._.letsencrypt-certs {
        inherit domain;
        adminEmail = "admin@${domain}";
        cloudflareTokenKey = "starcommand/selfhost/proxy/cloudflare/zone_dns_key";
      })

      # Cloudflare Tunnel - Exposes services without port forwarding
      (fleet.selfhost._.cloudflare-tunnel {
        inherit domain;
        tunnelId = "803700ac-6ca2-4041-94c7-3d1c9ef05e52";
        accountTagKey = "starcommand/selfhost/proxy/cloudflare/account_tag";
        tunnelSecretKey = "starcommand/selfhost/proxy/cloudflare/starcommand_tunnel/secret";
        dnsApiTokenKey = "starcommand/selfhost/proxy/cloudflare/starcommand_dns_key";
        noTLSVerify = true; # Let's Encrypt certs are trusted, but internal routing uses HTTP
        autoRouteDNS = true; # Automatically route DNS through tunnel
        # Manual ingress rules for services served directly by nginx (not proxied)
        manualIngress = [
          {
            hostname = "cloud.${domain}"; # Nextcloud
            service = "https://localhost";
          }
          {
            hostname = "media.${domain}"; # Jellyfin
            service = "https://localhost";
          }
          {
            hostname = "grocy.${domain}"; # Grocy
            service = "https://localhost";
          }
          {
            hostname = "torrents.${domain}"; # Deluge
            service = "https://localhost";
          }
          {
            hostname = "git.${domain}"; # Forgejo
            service = "https://localhost";
          }
          {
            hostname = "bookmarks.${domain}"; # Karakeep
            service = "https://localhost";
          }
          {
            hostname = "audiobooks.${domain}"; # Audiobookshelf
            service = "https://localhost";
          }
          {
            hostname = "finance.${domain}"; # Hledger
            service = "https://localhost";
          }
          {
            hostname = "home.${domain}"; # Home-Assistant
            service = "https://localhost";
          }
          {
            hostname = "chat.${domain}"; # Open-WebUI
            service = "https://localhost";
          }
          {
            hostname = "youtube.${domain}"; # Pinchflat
            service = "https://localhost";
          }
          {
            hostname = "photos.${domain}"; # Immich
            service = "https://localhost";
          }
          {
            hostname = "radarr.${domain}"; # Radarr
            service = "https://localhost";
          }
          {
            hostname = "sonarr.${domain}"; # Sonarr
            service = "https://localhost";
          }
          {
            hostname = "bazarr.${domain}"; # Bazarr
            service = "https://localhost";
          }
          {
            hostname = "readarr.${domain}"; # Readarr
            service = "https://localhost";
          }
          {
            hostname = "lidarr.${domain}"; # Lidarr
            service = "https://localhost";
          }
          {
            hostname = "jackett.${domain}"; # Jackett
            service = "https://localhost";
          }
        ];
      })
    ];
  };
}
