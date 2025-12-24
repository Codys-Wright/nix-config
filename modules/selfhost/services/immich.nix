# Immich Service
# Self-hosted photo and video backup solution
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.immich =
    {
      domain,
      subdomain,
      # SSO integration (required)
      ssoSecretKey,
      ssoSecretForAutheliaKey,
      authEndpoint,
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      port ? 2283,
      mediaLocation ? "/var/lib/immich",
      ssoClientID ? "immich",
      ssoAdminUserGroup ? "immich_admin",
      ssoUserGroup ? "immich_user",
      # Machine learning
      machineLearningEnable ? true,
      # Hardware acceleration
      accelerationDevices ? null,
      # Extra settings
      settings ? { },
      debug ? false,
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Immich - Self-hosted photo and video backup solution.

        Features:
        - Automatic photo/video backup from mobile
        - Machine learning for face recognition and search
        - Timeline and album organization
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
          # Immich configuration
          shb.immich = {
            enable = true;
            inherit
              domain
              subdomain
              port
              mediaLocation
              ;
            inherit accelerationDevices debug settings;
            ssl = sslCert;

            # Machine learning
            machineLearning = {
              enable = machineLearningEnable;
            };

            # SSO configuration
            sso = {
              enable = true;
              provider = "Authelia";
              endpoint = authEndpoint;
              clientID = ssoClientID;
              adminUserGroup = ssoAdminUserGroup;
              userGroup = ssoUserGroup;
              authorization_policy = "one_factor";
              autoRegister = true;
              autoLaunch = true;
              sharedSecret.result = config.shb.sops.secret."${ssoSecretKey}".result;
              sharedSecretForAuthelia.result = config.shb.sops.secret."${ssoSecretForAutheliaKey}".result;
            };
          };

          # Note: SOPS secrets are defined in the parent selfhost.nix module
          # with proper ownership settings
        };
    };
}
