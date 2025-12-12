# Jellyfin media server aspect module
{
  domain,
  subdomain ? "jellyfin",
  dcdomain,
  ldapAdminPasswordKey,
  ssoSecretKey,
  ssoSecretForAutheliaKey,
  authEndpoint,
}: {
  lib,
  config,
  __findFile,
  ...
}: let
  FTS = import <FTS.selfhost> {inherit lib config __findFile;};
in {
  # Ensure LLDAP groups for Jellyfin
  shb.lldap.ensureGroups = {
    jellyfin_user = {};
    jellyfin_admin = {};
  };

  # SOPS secrets for Jellyfin
  shb.sops.secret."${ldapAdminPasswordKey}".request = config.shb.jellyfin.ldap.adminPassword.request;
  shb.sops.secret."${ldapAdminPasswordKey}".settings.key = ldapAdminPasswordKey;

  shb.sops.secret."${ssoSecretKey}".request = config.shb.jellyfin.sso.sharedSecret.request;
  shb.sops.secret."${ssoSecretKey}".settings.key = ssoSecretKey;

  shb.sops.secret."${ssoSecretForAutheliaKey}".request = config.shb.jellyfin.sso.sharedSecretForAuthelia.request;
  shb.sops.secret."${ssoSecretForAutheliaKey}".settings.key = ssoSecretForAutheliaKey;

  # Jellyfin service configuration
  shb.jellyfin = {
    enable = true;
    inherit domain subdomain;

    ssl = (FTS.selfhost._.local-certs {}).shb.certs.certs.selfsigned.n;

    ldap = {
      enable = true;
      host = "127.0.0.1";
      port = config.shb.ldap.ldapPort;
      inherit dcdomain;
      userGroup = "jellyfin_user";
      adminGroup = "jellyfin_admin";
      adminPassword = {}; # Will be filled by SOPS
    };

    sso = {
      enable = true;
      provider = "Authelia";
      endpoint = authEndpoint;
      clientID = "jellyfin";
      userGroup = "jellyfin_user";
      adminUserGroup = "jellyfin_admin";
      authorization_policy = "one_factor";
      sharedSecret = {}; # Will be filled by SOPS
      sharedSecretForAuthelia = {}; # Will be filled by SOPS
    };
  };
}
