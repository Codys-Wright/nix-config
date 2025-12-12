# Arr stack (Radarr, Sonarr, Bazarr, Readarr, Lidarr, Jackett) aspect module
{
  domain,
  authEndpoint,
}: {
  lib,
  config,
  pkgs,
  __findFile,
  ...
}: let
  FTS = import <FTS.selfhost> {inherit lib config __findFile;};
in {
  # Ensure LLDAP group for Arr apps
  shb.lldap.ensureGroups = {
    arr_user = {};
  };

  # Create media group for file permissions
  users.groups.media = {};

  # SOPS secrets for API keys
  shb.sops.secret."starcommand/selfhost/apps/arr/radarr/api_key" = {
    request = config.shb.arr.radarr.settings.ApiKey.request;
    settings.key = "starcommand/selfhost/apps/arr/radarr/api_key";
  };

  shb.sops.secret."starcommand/selfhost/apps/arr/sonarr/api_key" = {
    request = config.shb.arr.sonarr.settings.ApiKey.request;
    settings.key = "starcommand/selfhost/apps/arr/sonarr/api_key";
  };

  shb.sops.secret."starcommand/selfhost/apps/arr/jackett/api_key" = {
    request = config.shb.arr.jackett.settings.ApiKey.request;
    settings.key = "starcommand/selfhost/apps/arr/jackett/api_key";
  };

  # Radarr - Movie management
  shb.arr.radarr = {
    enable = true;
    subdomain = "radarr";
    inherit domain authEndpoint;

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

    settings = {
      ApiKey = {}; # Will be filled by SOPS
      LogLevel = "info";
      Port = 7878;
    };
  };

  # Sonarr - TV show management
  shb.arr.sonarr = {
    enable = true;
    subdomain = "sonarr";
    inherit domain authEndpoint;

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

    settings = {
      ApiKey = {}; # Will be filled by SOPS
      LogLevel = "info";
      Port = 8989;
    };
  };

  # Bazarr - Subtitle management
  shb.arr.bazarr = {
    enable = true;
    subdomain = "bazarr";
    inherit domain authEndpoint;

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

    settings = {
      LogLevel = "info";
      Port = 6767;
    };
  };

  # Readarr - Book management
  shb.arr.readarr = {
    enable = true;
    subdomain = "readarr";
    inherit domain authEndpoint;

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

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

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

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

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

    settings = {
      ApiKey = {}; # Will be filled by SOPS
      Port = 9117;
    };
  };
}
