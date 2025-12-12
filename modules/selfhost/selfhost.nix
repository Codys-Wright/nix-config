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
      jellyfinSubdomain = "media";

      # Extract host information from aspect-chain if available
      # This allows us to configure the host's instantiate function
      hostInfo = aspectArgs.host or null;
    in {
      # Note: Hosts that include this aspect should set:
      #   den.hosts.<system>.<hostname>.instantiate =
      #     inputs.selfhostblocks.lib.<system>.patchedNixpkgs.nixosSystem;
      # This ensures the patched nixpkgs (with LLDAP enhancements) is used.

      includes = [
        # Let's Encrypt certificates with Cloudflare DNS
        (FTS.selfhost._.letsencrypt-certs {
          inherit domain;
          adminEmail = "admin@${domain}";
          cloudflareTokenKey = "starcommand/selfhost/proxy/cloudflare/zone_dns_key";
        })

        # Cloudflare Tunnel - Exposes services without port forwarding
        (FTS.selfhost._.cloudflare-tunnel {
          inherit domain;
          tunnelId = "803700ac-6ca2-4041-94c7-3d1c9ef05e52";
          accountTagKey = "starcommand/selfhost/proxy/cloudflare/account_tag";
          tunnelSecretKey = "starcommand/selfhost/proxy/cloudflare/starcommand_tunnel/secret";
          dnsApiTokenKey = "starcommand/selfhost/proxy/cloudflare/starcommand_dns_key";
          noTLSVerify = true; # Let's Encrypt certs are trusted, but internal routing uses HTTP
          autoRouteDNS = true; # Automatically route DNS through tunnel
          # Manual ingress rules for services served directly by nginx (not proxied)
          manualIngress = [
            {
              hostname = "cloud.${domain}"; # Nextcloud
              service = "https://localhost";
            }
            {
              hostname = "media.${domain}"; # Jellyfin
              service = "https://localhost";
            }
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
          radarrApiKey = "starcommand/selfhost/apps/arr/radarr/api_key";
          sonarrApiKey = "starcommand/selfhost/apps/arr/sonarr/api_key";
          jackettApiKey = "starcommand/selfhost/apps/arr/jackett/api_key";
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
          settings = {
            key = "starcommand/selfhost/auth/lldap/admin_password";
            owner = "jellyfin";
            group = "jellyfin";
            mode = "0440";
          };
        };

        # Jellyfin SSO secrets
        shb.sops.secret."starcommand/selfhost/apps/jellyfin/sso_secret" = {
          request = config.shb.jellyfin.sso.sharedSecret.request;
          settings = {
            key = "starcommand/selfhost/apps/jellyfin/sso_secret";
            owner = "jellyfin";
            group = "jellyfin";
            mode = "0440";
          };
        };

        # Authelia's copy of Jellyfin SSO secret - share same value
        shb.sops.secret."starcommand/selfhost/auth/authelia/jellyfin_sso_secret" = {
          request = config.shb.jellyfin.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/jellyfin/sso_secret";
        };

        # Arr stack API keys with proper ownership
        shb.sops.secret."starcommand/selfhost/apps/arr/radarr/api_key" = {
          settings = {
            key = "starcommand/selfhost/apps/arr/radarr/api_key";
            owner = "radarr";
            group = "radarr";
            mode = "0440";
          };
        };
        shb.sops.secret."starcommand/selfhost/apps/arr/sonarr/api_key" = {
          settings = {
            key = "starcommand/selfhost/apps/arr/sonarr/api_key";
            owner = "sonarr";
            group = "sonarr";
            mode = "0440";
          };
        };
        shb.sops.secret."starcommand/selfhost/apps/arr/jackett/api_key" = {
          settings = {
            key = "starcommand/selfhost/apps/arr/jackett/api_key";
            owner = "jackett";
            group = "jackett";
            mode = "0440";
          };
        };
      };
    };
  };
}
