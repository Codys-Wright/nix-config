# Forgejo Service
# Self-hosted Git service (GitHub alternative)
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.forgejo =
    {
      domain,
      subdomain,
      # Required secrets
      databasePasswordKey,
      # SSO integration (required)
      ssoSecretKey,
      ssoSecretForAutheliaKey,
      authEndpoint,
      # LDAP integration (required)
      ldapDcdomain,
      ldapAdminPasswordKey,
      ldapUserGroup ? "forgejo_user",
      ldapAdminGroup ? "forgejo_admin",
      # Optional parameters
      ssl ? null,
      sslCertName ? domain,
      repositoryRoot ? null,
      localActionRunner ? false,  # Disabled due to nixpkgs rename: forgejo-actions-runner -> forgejo-runner
      debug ? false,
      ssoClientID ? "forgejo",
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Forgejo - Self-hosted Git service.

        Features:
        - Git repository hosting
        - Pull requests and issues
        - CI/CD with Actions
        - LDAP and SSO integration

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
          # Forgejo configuration
          shb.forgejo = {
            enable = true;
            inherit domain subdomain;
            inherit repositoryRoot localActionRunner debug;
            ssl = sslCert;

            # Database password
            databasePassword.result = config.shb.sops.secret."${databasePasswordKey}".result;

            # LDAP configuration
            ldap = {
              enable = true;
              provider = "LLDAP";
              host = "127.0.0.1";
              port = 3890;
              dcdomain = ldapDcdomain;
              adminName = "admin";
              adminPassword.result = config.shb.sops.secret."${ldapAdminPasswordKey}".result;
              userGroup = ldapUserGroup;
              adminGroup = ldapAdminGroup;
            };

            # SSO configuration
            sso = {
              enable = true;
              provider = "Authelia";
              endpoint = authEndpoint;
              clientID = ssoClientID;
              authorization_policy = "one_factor";
              sharedSecret.result = config.shb.sops.secret."${ssoSecretKey}".result;
              sharedSecretForAuthelia.result = config.shb.sops.secret."${ssoSecretForAutheliaKey}".result;
            };

            # Users managed via LDAP/SSO, no declarative users needed
            users = { };
          };

          # Note: SOPS secrets are defined in the parent selfhost.nix module
          # with proper ownership settings
        };
    };
}
