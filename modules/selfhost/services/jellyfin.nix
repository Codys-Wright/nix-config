# Jellyfin media server aspect module
{
  FTS,
  lib,
  __findFile,
  ...
}: {
  FTS.selfhost._.jellyfin = {
    domain,
    subdomain ? "jellyfin",
    dcdomain,
    ldapAdminPasswordKey,
    ssoSecretKey,
    ssoSecretForAutheliaKey,
    authEndpoint,
    ...
  } @ aspectArgs: {
    class,
    aspect-chain,
  }: {
    nixos = {
      lib,
      config,
      ...
    }: {
      # Ensure LLDAP groups for Jellyfin
      shb.lldap.ensureGroups = {
        jellyfin_user = {};
        jellyfin_admin = {};
      };

      # Jellyfin service configuration
      shb.jellyfin = {
        enable = true;
        inherit domain subdomain;

        # Reference SSL certs from config (already set up by letsencrypt-certs aspect)
        # The certificate name matches the domain
        ssl = config.shb.certs.certs.letsencrypt.${domain};

        ldap = {
          enable = true;
          host = "127.0.0.1";
          port = config.shb.ldap.ldapPort;
          inherit dcdomain;
          userGroup = "jellyfin_user";
          adminGroup = "jellyfin_admin";
          # Reference the SOPS secret result
          adminPassword.result = config.shb.sops.secret."${ldapAdminPasswordKey}".result;
        };

        sso = {
          enable = true;
          provider = "Authelia";
          endpoint = authEndpoint;
          clientID = "jellyfin";
          userGroup = "jellyfin_user";
          adminUserGroup = "jellyfin_admin";
          authorization_policy = "one_factor";
          # Reference the SOPS secret results
          sharedSecret.result = config.shb.sops.secret."${ssoSecretKey}".result;
          sharedSecretForAuthelia.result = config.shb.sops.secret."${ssoSecretForAutheliaKey}".result;
        };
      };
    };
  };
}
