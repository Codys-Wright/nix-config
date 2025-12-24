# Deluge Service
# Torrent client with web UI
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.deluge =
    {
      domain,
      subdomain,
      # Required secrets
      localclientPasswordKey,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      downloadLocation ? "/srv/torrents",
      daemonPort ? 58846,
      daemonListenPorts ? [
        6881
        6889
      ],
      webPort ? 8112,
      proxyPort ? null,
      outgoingInterface ? null,
      # Performance settings
      maxActiveLimit ? 200,
      maxActiveDownloading ? 30,
      maxActiveSeeding ? 100,
      maxConnectionsGlobal ? 200,
      maxDownloadSpeed ? -1, # -1 = unlimited
      maxUploadSpeed ? 200,
      # SSO integration
      authEndpoint ? null,
      # Monitoring
      prometheusScraperPasswordKey ? null,
      # Extra users
      extraUsers ? { },
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Deluge - BitTorrent client with web UI.

        Features:
        - Web-based interface
        - Daemon mode for headless operation
        - Plugin support (Label auto-enabled with arr stack)
        - SSO integration
        - Prometheus monitoring

        Access at https://${subdomain}.${domain}
      '';

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          fqdn = "${subdomain}.${domain}";
          sslCert = if ssl != null then ssl else config.shb.certs.certs.letsencrypt.${sslCertName};
        in
        {
          # Deluge configuration
          shb.deluge = {
            enable = true;
            inherit domain subdomain;
            inherit daemonPort daemonListenPorts webPort;
            inherit proxyPort outgoingInterface;
            ssl = sslCert;

            # Authentication endpoint for SSO
            authEndpoint = authEndpoint;

            # Download and performance settings
            settings = {
              inherit downloadLocation;
              max_active_limit = maxActiveLimit;
              max_active_downloading = maxActiveDownloading;
              max_active_seeding = maxActiveSeeding;
              max_connections_global = maxConnectionsGlobal;
              max_download_speed = maxDownloadSpeed;
              max_upload_speed = maxUploadSpeed;
              dont_count_slow_torrents = true;
            };

            # Local client password (required)
            localclientPassword.result = config.shb.sops.secret."${localclientPasswordKey}".result;

            # Extra users (empty by default)
            extraUsers = extraUsers;

            # Prometheus monitoring (optional)
            prometheusScraperPassword = lib.mkIf (prometheusScraperPasswordKey != null) {
              result = config.shb.sops.secret."${prometheusScraperPasswordKey}".result;
            };
          };

          # SOPS secrets
          shb.sops.secret."${localclientPasswordKey}".request = config.shb.deluge.localclientPassword.request;
        }
        // lib.optionalAttrs (prometheusScraperPasswordKey != null) {
          shb.sops.secret."${prometheusScraperPasswordKey}".request =
            config.shb.deluge.prometheusScraperPassword.request;
        };
    };
}
