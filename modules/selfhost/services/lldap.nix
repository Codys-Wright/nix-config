# LLDAP Identity Provider Service
# Lightweight LDAP server for user authentication and authorization
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.lldap = {
    domain,
    subdomain,
    adminPasswordKey,
    jwtSecretKey,
    # Optional parameters
    ssl ? null,
    sslCertName ? domain,  # Use domain as cert name (e.g., "starcommand.live")
    ldapPort ? 3890,
    webUIListenPort ? 17170,
    users ? {},
    groups ? {},
    enforceGroups ? true,
    enforceUsers ? true,
    enforceUserMemberships ? true,
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      LLDAP - Lightweight LDAP identity provider.

      Provides user authentication and authorization with a simple web UI.
      Supports declarative user and group management.
    '';

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      dcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";
      # Use provided ssl or fall back to reading from config
      sslCert =
        if ssl != null
        then ssl
        else config.shb.certs.certs.letsencrypt.${sslCertName};
    in {
      # LLDAP configuration
      shb.lldap = {
        enable = true;
        inherit domain subdomain ldapPort webUIListenPort dcdomain;
        inherit enforceGroups enforceUsers enforceUserMemberships;
        ssl = sslCert;

        # Admin password from secrets
        ldapUserPassword.result = config.shb.sops.secret."${adminPasswordKey}".result;
        jwtSecret.result = config.shb.sops.secret."${jwtSecretKey}".result;

        # Declaratively manage groups
        ensureGroups = groups;

        # Declaratively manage users
        # For each user, if they have a passwordKey, set up the password.result
        ensureUsers =
          lib.mapAttrs (
            name: userConfig:
              if userConfig ? passwordKey
              then
                (lib.removeAttrs userConfig ["passwordKey" "passwordSopsFile"])
                // {
                  password.result = config.shb.sops.secret."${userConfig.passwordKey}".result;
                }
              else userConfig
          )
          users;
      };

      # SOPS secrets for LLDAP admin
      shb.sops.secret."${adminPasswordKey}".request = config.shb.lldap.ldapUserPassword.request;
      shb.sops.secret."${jwtSecretKey}".request = config.shb.lldap.jwtSecret.request;

      # Note: User password SOPS secrets must be set up by the parent module
      # to avoid circular dependency issues. The parent should set:
      # shb.sops.secret."<passwordKey>" = {
      #   request = config.shb.lldap.ensureUsers.<username>.password.request;
      #   settings = { sopsFile = ...; key = ...; };
      # };
    };
  };
}
