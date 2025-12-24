# Grocy Service
# Grocery and household management
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.grocy =
    {
      domain,
      subdomain,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain, # Use domain as cert name (e.g., "starcommand.live")
      currency ? "USD",
      culture ? "en",
      dataDir ? "/var/lib/grocy",
      extraServiceConfig ? { },
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Grocy - Grocery and household management.

        Features:
        - Shopping list management
        - Inventory tracking with expiration dates
        - Meal planning
        - Recipe management
        - Chore tracking
        - Battery tracking

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
          # Use provided ssl or fall back to reading from config
          sslCert = if ssl != null then ssl else config.shb.certs.certs.letsencrypt.${sslCertName};
        in
        {
          # Grocy configuration using selfhostblocks
          shb.grocy = {
            enable = true;
            inherit domain subdomain;
            inherit currency culture dataDir;
            ssl = sslCert;
            inherit extraServiceConfig;
          };
        };
    };
}
