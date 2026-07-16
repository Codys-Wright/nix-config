# Authentication stack: LLDAP identity provider + Authelia SSO
{
  inputs,
  fleet,
  ...
}:
let
  inherit (import ../_data/vars.nix) domain lldapSubdomain authSubdomain;
in
{
  fleet.selfhost._.stack-auth = {
    description = "Authentication stack: LLDAP identity provider and Authelia SSO";

    includes = [
      # LLDAP Identity Provider
      (fleet.selfhost._.lldap {
        inherit domain;
        subdomain = lldapSubdomain;
        adminPasswordKey = "starcommand/selfhost/auth/lldap/admin_password";
        jwtSecretKey = "starcommand/selfhost/auth/lldap/jwt_secret";

        # Service-specific groups
        # TODO: These should be automatically registered by each service module
        # For now, they're defined here but logically belong to their respective services:
        # - nextcloud_user, nextcloud_admin (from Nextcloud)
        # - grafana_user, grafana_admin (from Monitoring)
        # - vaultwarden_admin (from Vaultwarden)
        # - jellyfin_user, jellyfin_admin (from Jellyfin)
        # - arr_user (from Arr stack)
        # - lldap_admin, lldap_password_manager (from LLDAP)
        groups = {
          nextcloud_user = { };
          nextcloud_admin = { };
          grafana_user = { };
          grafana_admin = { };
          vaultwarden_admin = { };
          jellyfin_user = { };
          jellyfin_admin = { };
          arr_user = { };
          lldap_admin = { };
          lldap_password_manager = { };
          # New service groups
          forgejo_user = { };
          forgejo_admin = { };
          karakeep_user = { };
          audiobookshelf_user = { };
          audiobookshelf_admin = { };
          hledger_user = { };
          homeassistant_user = { };
          open-webui_user = { };
          open-webui_admin = { };
          pinchflat_user = { };
          immich_user = { };
          immich_admin = { };
          grocy_user = { };
          deluge_user = { };
        };

        # Define users
        users = {
          codywright = {
            email = "acodywright@gmail.com";
            firstName = "Cody";
            lastName = "Wright";
            groups = [
              "nextcloud_user"
              "nextcloud_admin"
              "grafana_user"
              "grafana_admin"
              "deluge_user"
              "vaultwarden_admin"
              "jellyfin_user"
              "jellyfin_admin"
              "arr_user"
              "lldap_admin"
              "lldap_password_manager"
              # New service groups
              "forgejo_user"
              "forgejo_admin"
              "karakeep_user"
              "audiobookshelf_user"
              "audiobookshelf_admin"
              "hledger_user"
              "homeassistant_user"
              "open-webui_user"
              "open-webui_admin"
              "pinchflat_user"
              "immich_user"
              "immich_admin"
            ];
            passwordKey = "cody/personal/password";
            passwordSopsFile = "${inputs.nix-secrets}/sops/users/cody.yaml";
          };

          amywright = {
            email = "amy.wright@example.com"; # TODO: Update with real email
            firstName = "Amy";
            lastName = "Wright";
            groups = [
              "nextcloud_user"
              "jellyfin_user"
              "grocy_user"
            ];
            passwordKey = "starcommand/selfhost/users/amy_wright/password";
            passwordSopsFile = "${inputs.nix-secrets}/sops/users/starcommand.yaml";
          };

          tommywright = {
            email = "tommy.wright@example.com"; # TODO: Update with real email
            firstName = "Tommy";
            lastName = "Wright";
            groups = [
              "nextcloud_user"
              "jellyfin_user"
              "grocy_user"
            ];
            passwordKey = "starcommand/selfhost/users/tommy_wright/password";
            passwordSopsFile = "${inputs.nix-secrets}/sops/users/starcommand.yaml";
          };

          brizacharias = {
            email = "bri.zacharias@example.com"; # TODO: Update with real email
            firstName = "Bri";
            lastName = "Zacharias";
            groups = [
              "nextcloud_user"
              "jellyfin_user"
              "grocy_user"
            ];
            passwordKey = "starcommand/selfhost/users/bri_zacharias/password";
            passwordSopsFile = "${inputs.nix-secrets}/sops/users/starcommand.yaml";
          };
        };
      })

      # Authelia SSO Provider
      (fleet.selfhost._.authelia {
        inherit domain;
        subdomain = authSubdomain;
        # LDAP connection info - will be read from config.shb.lldap
        ldapPort = 3890; # Same as LLDAP
        ldapHostname = "127.0.0.1";
        dcdomain = "dc=${builtins.replaceStrings [ "." ] [ ",dc=" ] domain}";

        # Access control rules for protected services
        accessControl = {
          defaultPolicy = "deny";
          rules = [
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:nextcloud_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:jellyfin_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:grocy_user" ];
            }
            {
              domain = "torrents.${domain}";
              policy = "two_factor";
              subject = [ "group:deluge_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:arr_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:lldap_admin" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:vaultwarden_admin" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:grafana_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:forgejo_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:karakeep_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:audiobookshelf_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:hledger_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:homeassistant_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:open-webui_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:pinchflat_user" ];
            }
            {
              domain = "*.${domain}";
              policy = "two_factor";
              subject = [ "group:immich_user" ];
            }
          ];
        };

        # Secret keys
        jwtSecretKey = "starcommand/selfhost/auth/authelia/jwt_secret";
        ldapAdminPasswordKey = "starcommand/selfhost/auth/authelia/ldap_admin_password";
        sessionSecretKey = "starcommand/selfhost/auth/authelia/session_secret";
        storageEncryptionKey = "starcommand/selfhost/auth/authelia/storage_encryption_key";
        oidcHmacSecretKey = "starcommand/selfhost/auth/authelia/oidc_hmac_secret";
        oidcIssuerPrivateKey = "starcommand/selfhost/auth/authelia/oidc_issuer_private_key";
      })
    ];
  };
}
