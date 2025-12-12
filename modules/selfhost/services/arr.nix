# Arr stack (Radarr, Sonarr, Bazarr, Readarr, Lidarr, Jackett) aspect module
{
  FTS,
  lib,
  __findFile,
  ...
}: {
  FTS.selfhost._.arr = {
    domain,
    authEndpoint,
    radarrApiKey,
    sonarrApiKey,
    jackettApiKey,
    ...
  } @ aspectArgs: {
    class,
    aspect-chain,
  }: {
    nixos = {
      lib,
      config,
      pkgs,
      ...
    }: {
      # Ensure LLDAP group for Arr apps
      shb.lldap.ensureGroups = {
        arr_user = {};
      };

      # Create media group for file permissions
      users.groups.media = {};

      # Radarr - Movie management
      shb.arr.radarr = {
        enable = true;
        subdomain = "radarr";
        inherit domain authEndpoint;

        # Reference SSL certs from config (already set up by letsencrypt-certs aspect)
        ssl = config.shb.certs.certs.letsencrypt.${domain};

        settings = {
          # Radarr uses .source (file path) not .request (contract)
          ApiKey.source = config.shb.sops.secret."${radarrApiKey}".result.path;
          LogLevel = "info";
        };
      };

      # Sonarr - TV show management
      shb.arr.sonarr = {
        enable = true;
        subdomain = "sonarr";
        inherit domain authEndpoint;

        ssl = config.shb.certs.certs.letsencrypt.${domain};

        settings = {
          # Sonarr uses .source (file path) not .request (contract)
          ApiKey.source = config.shb.sops.secret."${sonarrApiKey}".result.path;
          LogLevel = "info";
        };
      };

      # Bazarr - Subtitle management
      shb.arr.bazarr = {
        enable = true;
        subdomain = "bazarr";
        inherit domain authEndpoint;

        ssl = config.shb.certs.certs.letsencrypt.${domain};

        settings = {
          LogLevel = "info";
          # Port is read-only, defaults to 6767
        };
      };

      # Readarr - Book management
      shb.arr.readarr = {
        enable = true;
        subdomain = "readarr";
        inherit domain authEndpoint;

        ssl = config.shb.certs.certs.letsencrypt.${domain};

        settings = {
          LogLevel = "info";
          Port = 8787;
        };
      };

      # Lidarr - Music management
      shb.arr.lidarr = {
        enable = true;
        subdomain = "lidarr";
        inherit domain authEndpoint;

        ssl = config.shb.certs.certs.letsencrypt.${domain};

        settings = {
          LogLevel = "info";
          Port = 8686;
        };
      };

      # Jackett - Torrent indexer proxy
      shb.arr.jackett = {
        enable = true;
        subdomain = "jackett";
        inherit domain authEndpoint;

        ssl = config.shb.certs.certs.letsencrypt.${domain};

        settings = {
          # Jackett uses .source (file path) not .request (contract)
          ApiKey.source = config.shb.sops.secret."${jackettApiKey}".result.path;
          # Port is read-only, defaults to 9117
        };
      };
    };
  };
}
