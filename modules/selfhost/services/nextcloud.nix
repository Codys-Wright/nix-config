# Nextcloud Server Service
# Self-hosted file sync and collaboration platform
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.nextcloud = {
    domain,
    subdomain,
    adminPasswordKey,
    # LDAP configuration
    ldap ? {},
    # SSO configuration
    sso ? {},
    # Optional parameters
    ssl ? null,
    sslCertName ? domain,  # Use domain as cert name (e.g., "starcommand.live")
    dataDir ? "/var/lib/nextcloud",
    defaultPhoneRegion ? "US",
    enablePreviewGenerator ? true,
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      Nextcloud - Self-hosted file sync and collaboration platform.

      Provides file storage, sharing, and collaboration tools.
      Supports LDAP authentication and SSO integration.
    '';

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      # Use provided ssl or fall back to reading from config
      sslCert =
        if ssl != null
        then ssl
        else config.shb.certs.certs.letsencrypt.${sslCertName};

      # Check if LDAP is enabled
      ldapEnabled = ldap != {} && ldap ? enable && ldap.enable;

      # Check if SSO is enabled
      ssoEnabled = sso != {} && sso ? enable && sso.enable;

      # Check if we have the necessary keys
      hasLdapPasswordKey = ldapEnabled && ldap ? adminPasswordKey;
      hasSsoKeys = ssoEnabled && sso ? secretKey && sso ? secretForAutheliaKey;
    in {
      # Nextcloud configuration
      shb.nextcloud = {
        enable = true;
        inherit domain subdomain dataDir defaultPhoneRegion;
        port = lib.mkForce null; # Use SSL
        ssl = sslCert;
        tracing = null;

        # Admin password from secrets
        adminPass.result = config.shb.sops.secret."${adminPasswordKey}".result;

        apps = {
          # Preview generator for thumbnails
          previewgenerator.enable = enablePreviewGenerator;

          # LDAP integration (if configured)
          ldap = lib.mkIf ldapEnabled {
            enable = true;
            host = ldap.host or "127.0.0.1";
            port = ldap.port;
            dcdomain = ldap.dcdomain;
            adminName = ldap.adminName or "admin";
            adminPassword.result = config.shb.sops.secret."${ldap.adminPasswordKey}".result;
            userGroup = ldap.userGroup;
          };

          # SSO integration (if configured)
          sso = lib.mkIf ssoEnabled {
            enable = true;
            endpoint = sso.endpoint;
            clientID = sso.clientID or "nextcloud";
            fallbackDefaultAuth = sso.fallbackDefaultAuth or true;
            secret.result = config.shb.sops.secret."${sso.secretKey}".result;
            secretForAuthelia.result = config.shb.sops.secret."${sso.secretForAutheliaKey}".result;
          };
        };
      };

      # SOPS secret for Nextcloud admin password
      shb.sops.secret."${adminPasswordKey}".request = config.shb.nextcloud.adminPass.request;

      # NOTE: LDAP and SSO secrets must be set up by the parent module
      # because they require settings.key overrides for secret sharing.
      # Parent should set up:
      #   - ldap.adminPasswordKey with settings.key pointing to LLDAP admin password
      #   - sso.secretKey for Nextcloud's SSO secret
      #   - sso.secretForAutheliaKey with settings.key pointing to sso.secretKey
    };
  };
}
