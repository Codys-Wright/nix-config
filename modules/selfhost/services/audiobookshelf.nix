# Audiobookshelf Service
# Audiobook and podcast server
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.audiobookshelf =
    {
      domain,
      subdomain,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      webPort ? 8113,
      # SSO integration (required)
      ssoSecretKey,
      ssoSecretForAutheliaKey,
      authEndpoint,
      ssoClientID ? "audiobookshelf",
      ssoAdminUserGroup ? "audiobookshelf_admin",
      ssoUserGroup ? "audiobookshelf_user",
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Audiobookshelf - Self-hosted audiobook and podcast server.

        Features:
        - Stream audiobooks and podcasts
        - Multi-user support with progress sync
        - Mobile apps available
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
          # Audiobookshelf configuration
          shb.audiobookshelf = {
            enable = true;
            inherit domain subdomain webPort;
            ssl = sslCert;

            # SSO configuration
            sso = {
              enable = true;
              provider = "Authelia";
              endpoint = authEndpoint;
              clientID = ssoClientID;
              adminUserGroup = ssoAdminUserGroup;
              userGroup = ssoUserGroup;
              authorization_policy = "one_factor";
              sharedSecret.result = config.shb.sops.secret."${ssoSecretKey}".result;
              sharedSecretForAuthelia.result = config.shb.sops.secret."${ssoSecretForAutheliaKey}".result;
            };
          };

          # Note: SOPS secrets are defined in the parent selfhost.nix module
          # with proper ownership settings
        };
    };
}
