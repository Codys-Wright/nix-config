# Media stack: Jellyfin, Arr, Deluge, Pinchflat, Audiobookshelf, Immich
{
  fleet,
  ...
}:
let
  inherit (import ../_data/vars.nix)
    domain
    authSubdomain
    jellyfinSubdomain
    delugeSubdomain
    audiobookshelfSubdomain
    pinchflatSubdomain
    immichSubdomain
    ;
in
{
  fleet.selfhost._.stack-media = {
    description = "Media stack: Jellyfin, Arr suite, Deluge, Pinchflat, Audiobookshelf, Immich";

    includes = [
      # Jellyfin Media Server
      # NOTE: Media libraries must be configured via web UI at https://media.starcommand.live
      # Recommended library paths (pre-created on /mnt/storage):
      #   Movies: /mnt/storage/media/movies
      #   TV Shows: /mnt/storage/media/tv
      #   Music: /mnt/storage/media/music
      #   Audiobooks: /mnt/storage/media/audiobooks
      # See docs/jellyfin-setup.md for detailed setup instructions
      (fleet.selfhost._.jellyfin {
        inherit domain;
        subdomain = jellyfinSubdomain;
        dcdomain = "dc=${builtins.replaceStrings [ "." ] [ ",dc=" ] domain}";
        ldapAdminPasswordKey = "starcommand/selfhost/apps/jellyfin/ldap_admin_password";
        ssoSecretKey = "starcommand/selfhost/apps/jellyfin/sso_secret";
        ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/jellyfin_sso_secret";
        authEndpoint = "https://${authSubdomain}.${domain}";
      })

      # Arr Stack - Media management (Radarr, Sonarr, Bazarr, Readarr, Lidarr, Jackett)
      (fleet.selfhost._.arr {
        inherit domain;
        authEndpoint = "https://${authSubdomain}.${domain}";
        radarrApiKey = "starcommand/selfhost/apps/arr/radarr/api_key";
        sonarrApiKey = "starcommand/selfhost/apps/arr/sonarr/api_key";
        jackettApiKey = "starcommand/selfhost/apps/arr/jackett/api_key";
      })

      # Deluge - BitTorrent client
      (fleet.selfhost._.deluge {
        inherit domain;
        subdomain = delugeSubdomain;
        downloadLocation = "/mnt/storage/torrents"; # Torrents on merged storage
        localclientPasswordKey = "starcommand/selfhost/apps/deluge/localclient_password";
        prometheusScraperPasswordKey = "starcommand/selfhost/apps/deluge/prometheus_scraper_password";
        authEndpoint = "https://${authSubdomain}.${domain}";
      })

      # Pinchflat - YouTube downloader
      # NOTE: Videos saved to /mnt/storage/youtube
      # To watch in Jellyfin: Add /mnt/storage/youtube as a library
      # Or configure Pinchflat via web UI to save to specific Jellyfin folders:
      #   - Music videos → /mnt/storage/media/music
      #   - Documentaries → /mnt/storage/media/movies
      #   - Podcasts → /mnt/storage/media/tv
      (fleet.selfhost._.pinchflat {
        inherit domain;
        subdomain = pinchflatSubdomain;
        mediaDir = "/mnt/storage/youtube"; # Downloaded videos on merged storage
        timeZone = "America/Chicago";
        secretKeyBaseKey = "starcommand/selfhost/apps/pinchflat/secret_key_base";
        sso = {
          authEndpoint = "https://${authSubdomain}.${domain}";
        };
      })

      # Audiobookshelf - Audiobook server
      (fleet.selfhost._.audiobookshelf {
        inherit domain;
        subdomain = audiobookshelfSubdomain;
        # SSO
        authEndpoint = "https://${authSubdomain}.${domain}";
        ssoSecretKey = "starcommand/selfhost/apps/audiobookshelf/sso_secret";
        ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/audiobookshelf_sso_secret";
      })

      # Immich - Photo and video backup
      (fleet.selfhost._.immich {
        inherit domain;
        subdomain = immichSubdomain;
        # App state on btrfs, photos on merged storage
        mediaLocation = "/mnt/storage/photos"; # Photo library on merged storage
        # SSO
        authEndpoint = "https://${authSubdomain}.${domain}";
        ssoSecretKey = "starcommand/selfhost/apps/immich/sso_secret";
        ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/immich_sso_secret";
      })
    ];
  };
}
