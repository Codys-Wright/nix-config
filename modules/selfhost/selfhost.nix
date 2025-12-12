# Self-hosting services coordination module using SelfHostBlocks
{
  inputs,
  lib,
  FTS,
  den,
  ...
}: {
  FTS.selfhost = {
    description = ''
      Self-hosting services stack using SelfHostBlocks.

      Provides complete self-hosted infrastructure including:
      - Authentication (LLDAP, Authelia SSO)
      - Applications (Nextcloud with LDAP & SSO)
      - SSL/TLS certificates (self-signed CA)
      - Local DNS resolution (dnsmasq)

      Note: Automatically configures hosts to use selfhostblocks' patched nixpkgs.
      This provides patched LLDAP options and other enhancements.

      Secrets managed via users/starcommand/secrets.yaml
    '';

    # Make this a parametric aspect (even if we don't use parameters yet)
    __functor = _: args: {
      class,
      aspect-chain,
      ...
    } @ aspectArgs: let
      domain = "starcommand.live";
      nextcloudSubdomain = "cloud";
      lldapSubdomain = "ldap";
      authSubdomain = "auth";
      grafanaSubdomain = "grafana";
      vaultwardenSubdomain = "vault";
      jellyfinSubdomain = "jellyfin";

      # Extract host information from aspect-chain if available
      # This allows us to configure the host's instantiate function
      hostInfo = aspectArgs.host or null;
    in {
      # Note: Hosts that include this aspect should set:
      #   den.hosts.<system>.<hostname>.instantiate =
      #     inputs.selfhostblocks.lib.<system>.patchedNixpkgs.nixosSystem;
      # This ensures the patched nixpkgs (with LLDAP enhancements) is used.

      includes = [
        # Local certificates and DNS
        (FTS.selfhost._.local-certs {
          inherit domain;
          subdomains = [
            nextcloudSubdomain
            lldapSubdomain
            authSubdomain
            grafanaSubdomain
            vaultwardenSubdomain
            jellyfinSubdomain
            # Arr stack subdomains
            "radarr"
            "sonarr"
            "bazarr"
            "readarr"
            "lidarr"
            "jackett"
          ];
        })

        # LLDAP Identity Provider
        (FTS.selfhost._.lldap {
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
            nextcloud_user = {};
            nextcloud_admin = {};
            grafana_user = {};
            grafana_admin = {};
            vaultwarden_admin = {};
            jellyfin_user = {};
            jellyfin_admin = {};
            arr_user = {};
            lldap_admin = {};
            lldap_password_manager = {};
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
                "vaultwarden_admin"
                "jellyfin_user"
                "jellyfin_admin"
                "arr_user"
                "lldap_admin"
                "lldap_password_manager"
              ];
              passwordKey = "cody/personal/password";
              passwordSopsFile = ../../users/cody/secrets.yaml;
            };
          };
        })

        # Authelia SSO Provider
        (FTS.selfhost._.authelia {
          inherit domain;
          subdomain = authSubdomain;
          # LDAP connection info - will be read from config.shb.lldap
          ldapPort = 3890; # Same as LLDAP
          ldapHostname = "127.0.0.1";
          dcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";

          # Secret keys
          jwtSecretKey = "starcommand/selfhost/auth/authelia/jwt_secret";
          ldapAdminPasswordKey = "starcommand/selfhost/auth/authelia/ldap_admin_password";
          sessionSecretKey = "starcommand/selfhost/auth/authelia/session_secret";
          storageEncryptionKey = "starcommand/selfhost/auth/authelia/storage_encryption_key";
          oidcHmacSecretKey = "starcommand/selfhost/auth/authelia/oidc_hmac_secret";
          oidcIssuerPrivateKey = "starcommand/selfhost/auth/authelia/oidc_issuer_private_key";
        })

        # Nextcloud Server
        (FTS.selfhost._.nextcloud {
          inherit domain;
          subdomain = nextcloudSubdomain;
          adminPasswordKey = "starcommand/selfhost/apps/nextcloud/admin_password";

          # LDAP integration
          ldap = {
            enable = true;
            port = 3890; # Same as LLDAP
            dcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";
            adminPasswordKey = "starcommand/selfhost/apps/nextcloud/ldap_admin_password";
            userGroup = "nextcloud_user";
          };

          # SSO integration
          sso = {
            enable = true;
            endpoint = "https://${authSubdomain}.${domain}";
            clientID = "nextcloud";
            secretKey = "starcommand/selfhost/apps/nextcloud/sso_secret";
            secretForAutheliaKey = "starcommand/selfhost/auth/authelia/nextcloud_sso_secret";
          };
        })

        # Monitoring Stack
        (FTS.selfhost._.monitoring {
          inherit domain;
          subdomain = grafanaSubdomain;
          adminPasswordKey = "starcommand/selfhost/monitoring/grafana/admin_password";
          secretKeyKey = "starcommand/selfhost/monitoring/grafana/secret_key";
          contactPoints = ["acodywright@gmail.com"];

          # LDAP integration
          ldap = {
            userGroup = "grafana_user";
            adminGroup = "grafana_admin";
          };

          # SSO integration
          sso = {
            enable = true;
            authEndpoint = "https://${authSubdomain}.${domain}";
            sharedSecretKey = "starcommand/selfhost/monitoring/grafana/oidc_secret";
            sharedSecretForAutheliaKey = "starcommand/selfhost/monitoring/grafana/oidc_secret_for_authelia";
          };
        })

        # Vaultwarden Password Manager
        (FTS.selfhost._.vaultwarden {
          inherit domain;
          subdomain = vaultwardenSubdomain;
          databasePasswordKey = "starcommand/selfhost/apps/vaultwarden/database_password";
          authEndpoint = "https://${authSubdomain}.${domain}";
        })

        # Jellyfin Media Server
        (FTS.selfhost._.jellyfin {
          inherit domain;
          subdomain = jellyfinSubdomain;
          dcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";
          ldapAdminPasswordKey = "starcommand/selfhost/apps/jellyfin/ldap_admin_password";
          ssoSecretKey = "starcommand/selfhost/apps/jellyfin/sso_secret";
          ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/jellyfin_sso_secret";
          authEndpoint = "https://${authSubdomain}.${domain}";
        })

        # Arr Stack - Media management (Radarr, Sonarr, Bazarr, Readarr, Lidarr, Jackett)
        (FTS.selfhost._.arr {
          inherit domain;
          authEndpoint = "https://${authSubdomain}.${domain}";
        })
      ];

      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # Import SelfHostBlocks modules
        # default imports everything except sops
        imports = [
          inputs.selfhostblocks.nixosModules.default
          inputs.selfhostblocks.nixosModules.sops
          inputs.sops-nix.nixosModules.default
        ];

        # SOPS configuration - points to starcommand user secrets
        sops = {
          defaultSopsFile = lib.mkDefault ../../users/starcommand/secrets.yaml;
          # Use host's SSH key for decryption during build
          age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        };

        # Nginx reverse proxy
        shb.nginx.accessLog = lib.mkDefault true;
        shb.nginx.debugLog = lib.mkDefault false;

        # SOPS secret for codywright's password (from cody's personal secrets file)
        # This needs to be in the parent module to avoid circular dependency
        shb.sops.secret."cody/personal/password" = {
          request = config.shb.lldap.ensureUsers.codywright.password.request;
          settings = {
            sopsFile = ../../users/cody/secrets.yaml;
            key = "cody/personal/password";
          };
        };

        # Secret sharing configuration
        # Set up secrets that need to be shared between services

        # Authelia LDAP admin password - reuse LLDAP admin password
        shb.sops.secret."starcommand/selfhost/auth/authelia/ldap_admin_password".settings.key = "starcommand/selfhost/auth/lldap/admin_password";

        # Nextcloud LDAP admin password - reuse LLDAP admin password
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/ldap_admin_password" = {
          request = config.shb.nextcloud.apps.ldap.adminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password";
        };

        # Nextcloud SSO secret
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".request = config.shb.nextcloud.apps.sso.secret.request;

        # Authelia's copy of Nextcloud SSO secret - share same value
        shb.sops.secret."starcommand/selfhost/auth/authelia/nextcloud_sso_secret" = {
          request = config.shb.nextcloud.apps.sso.secretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/nextcloud/sso_secret";
        };

        # Monitoring SSO secrets - set up by parent to share secret with Authelia
        shb.sops.secret."starcommand/selfhost/monitoring/grafana/oidc_secret".request =
          config.shb.monitoring.sso.sharedSecret.request;

        shb.sops.secret."starcommand/selfhost/monitoring/grafana/oidc_secret_for_authelia" = {
          request = config.shb.monitoring.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/monitoring/grafana/oidc_secret"; # Share the same secret
        };

        # Jellyfin LDAP admin password - reuse LLDAP admin password
        shb.sops.secret."starcommand/selfhost/apps/jellyfin/ldap_admin_password" = {
          request = config.shb.jellyfin.ldap.adminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password";
        };

        # Jellyfin SSO secret
        shb.sops.secret."starcommand/selfhost/apps/jellyfin/sso_secret".request =
          config.shb.jellyfin.sso.sharedSecret.request;

        # Authelia's copy of Jellyfin SSO secret - share same value
        shb.sops.secret."starcommand/selfhost/auth/authelia/jellyfin_sso_secret" = {
          request = config.shb.jellyfin.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/jellyfin/sso_secret";
        };
      };
    };
  };
}
