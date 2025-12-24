# Open-WebUI Service
# Web UI for LLMs (ChatGPT-like interface)
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.open-webui =
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
      port ? 12444,
      ssoClientID ? "open-webui",
      # LDAP integration
      ldapUserGroup ? "open-webui_user",
      ldapAdminGroup ? "open-webui_admin",
      # Extra environment variables
      extraEnvironment ? { },
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Open-WebUI - Web UI for LLMs.

        Features:
        - ChatGPT-like interface
        - Multiple model support
        - Conversation history
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
          # Open-WebUI configuration
          shb.open-webui = {
            enable = true;
            inherit domain subdomain port;
            ssl = sslCert;
            environment = extraEnvironment;

            # LDAP configuration
            ldap = {
              userGroup = ldapUserGroup;
              adminGroup = ldapAdminGroup;
            };

            # SSO configuration
            sso = {
              enable = true;
              authEndpoint = authEndpoint;
              clientID = ssoClientID;
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
