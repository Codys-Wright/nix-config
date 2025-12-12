# Authelia SSO/OIDC Authentication Service
# Provides single sign-on and two-factor authentication
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.authelia = {
    domain,
    subdomain,
    ldapPort,
    ldapHostname,
    dcdomain,
    # Secret keys for SOPS
    jwtSecretKey,
    ldapAdminPasswordKey,
    sessionSecretKey,
    storageEncryptionKey,
    oidcHmacSecretKey,
    oidcIssuerPrivateKey,
    # Optional parameters
    ssl ? null,
    sslCertName ? "starcommand",
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      Authelia - SSO and OIDC authentication provider.

      Provides single sign-on (SSO) with LDAP backend and OIDC for applications.
      Supports two-factor authentication and advanced access control.
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
        else config.shb.certs.certs.selfsigned.${sslCertName};
    in {
      # Authelia configuration
      shb.authelia = {
        enable = true;
        inherit domain subdomain ldapPort ldapHostname dcdomain;
        ssl = sslCert;

        secrets = {
          jwtSecret.result = config.shb.sops.secret."${jwtSecretKey}".result;
          ldapAdminPassword.result = config.shb.sops.secret."${ldapAdminPasswordKey}".result;
          sessionSecret.result = config.shb.sops.secret."${sessionSecretKey}".result;
          storageEncryptionKey.result = config.shb.sops.secret."${storageEncryptionKey}".result;
          identityProvidersOIDCHMACSecret.result = config.shb.sops.secret."${oidcHmacSecretKey}".result;
          identityProvidersOIDCIssuerPrivateKey.result = config.shb.sops.secret."${oidcIssuerPrivateKey}".result;
        };
      };

      # SOPS secrets for Authelia
      shb.sops.secret."${jwtSecretKey}".request = config.shb.authelia.secrets.jwtSecret.request;
      shb.sops.secret."${ldapAdminPasswordKey}".request = config.shb.authelia.secrets.ldapAdminPassword.request;
      shb.sops.secret."${sessionSecretKey}".request = config.shb.authelia.secrets.sessionSecret.request;
      shb.sops.secret."${storageEncryptionKey}".request = config.shb.authelia.secrets.storageEncryptionKey.request;
      shb.sops.secret."${oidcHmacSecretKey}".request = config.shb.authelia.secrets.identityProvidersOIDCHMACSecret.request;
      shb.sops.secret."${oidcIssuerPrivateKey}".request = config.shb.authelia.secrets.identityProvidersOIDCIssuerPrivateKey.request;
    };
  };
}
