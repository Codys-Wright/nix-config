# Hledger Service
# Plain-text accounting
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.hledger =
    {
      domain,
      subdomain,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      port ? 5000,
      dataDir ? "/var/lib/hledger",
      localNetworkIPRange ? null,
      # SSO integration
      authEndpoint ? null,
      # Extra arguments
      extraArguments ? [ "--forecast" ],
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Hledger - Plain-text accounting.

        Features:
        - Double-entry bookkeeping
        - Plain text journal files
        - Web interface
        - Reports and charts
        - SSO integration

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
          # Hledger configuration
          shb.hledger = {
            enable = true;
            inherit
              domain
              subdomain
              port
              dataDir
              ;
            inherit localNetworkIPRange extraArguments;
            ssl = sslCert;

            # SSO integration
            authEndpoint = authEndpoint;
          };
        };
    };
}
