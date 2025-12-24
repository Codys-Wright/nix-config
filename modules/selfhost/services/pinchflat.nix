# Pinchflat Service
# YouTube video downloader
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.pinchflat =
    {
      domain,
      subdomain,
      # Required
      mediaDir,
      timeZone,
      secretKeyBaseKey,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      port ? 8945,
      # LDAP integration
      ldap ? null,
      # SSO integration
      sso ? null,
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Pinchflat - YouTube video downloader.

        Features:
        - Automatic YouTube downloads
        - Channel/playlist subscriptions
        - Scheduling
        - Media organization

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
          # Pinchflat configuration
          shb.pinchflat = {
            enable = true;
            inherit domain subdomain port;
            inherit mediaDir timeZone;
            ssl = sslCert;

            # Secret key base (required, at least 64 chars)
            secretKeyBase.result = config.shb.sops.secret."${secretKeyBaseKey}".result;

            # LDAP configuration
            ldap = lib.mkIf (ldap != null) {
              enable = true;
              userGroup = ldap.userGroup or "pinchflat_user";
            };

            # SSO configuration
            sso = lib.mkIf (sso != null) {
              enable = true;
              authEndpoint = sso.authEndpoint;
              authorization_policy = sso.authorization_policy or "one_factor";
            };
          };

          # SOPS secrets
          shb.sops.secret."${secretKeyBaseKey}".request = config.shb.pinchflat.secretKeyBase.request;
        };
    };
}
