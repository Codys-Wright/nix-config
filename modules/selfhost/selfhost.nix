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
      domain = "starcommand.local";
      nextcloudSubdomain = "cloud";
      ldapSubdomain = "ldap";
      authSubdomain = "auth";

      # Extract host information from aspect-chain if available
      # This allows us to configure the host's instantiate function
      hostInfo = aspectArgs.host or null;
    in {
      # Note: Hosts that include this aspect should set:
      #   den.hosts.<system>.<hostname>.instantiate =
      #     inputs.selfhostblocks.lib.<system>.patchedNixpkgs.nixosSystem;
      # This ensures the patched nixpkgs (with LLDAP enhancements) is used.

      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # Import SelfHostBlocks modules
        # These use selfhostblocks' patched nixpkgs for enhanced options
        imports = [
          inputs.selfhostblocks.nixosModules.lldap
          inputs.selfhostblocks.nixosModules.sops
          inputs.selfhostblocks.nixosModules.authelia
          inputs.selfhostblocks.nixosModules.nextcloud-server
          inputs.selfhostblocks.nixosModules.nginx
          inputs.selfhostblocks.nixosModules.ssl
          inputs.sops-nix.nixosModules.default
        ];

        # SOPS configuration - points to starcommand user secrets
        sops = {
          defaultSopsFile = lib.mkDefault ../../users/starcommand/secrets.yaml;
          # Use host's SSH key for decryption during build
          age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        };

        # SSL certificates (self-signed CA)
        shb.certs = {
          cas.selfsigned.myca = {
            name = "Homelab CA";
          };
          certs.selfsigned.n = {
            ca = config.shb.certs.cas.selfsigned.myca;
            domain = "*.${domain}";
            group = "nginx";
          };
        };

        # LLDAP - Lightweight LDAP identity provider
        # This tests if we're using the patched nixpkgs (which adds the enforceGroups option)
        shb.lldap = {
          enable = true;
          inherit domain;
          subdomain = ldapSubdomain;
          ldapPort = 3890;
          webUIListenPort = 17170;
          dcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";
          ssl = config.shb.certs.certs.selfsigned.n;
          # Generated with: openssl rand -base64 32
          ldapUserPassword.result =
            config.shb.sops.secret."starcommand/selfhost/auth/lldap/admin_password".result;
          # Generated with: openssl rand -base64 32
          jwtSecret.result = config.shb.sops.secret."starcommand/selfhost/auth/lldap/jwt_secret".result;

          # Declaratively manage groups - they will be created automatically
          ensureGroups = {
            nextcloud_user = {}; # Users who can access Nextcloud
            nextcloud_admin = {}; # Nextcloud administrators
          };

          # Declaratively manage users
          ensureUsers = {
            CodyWright = {
              email = "acodywright@gmail.com";
              firstName = "Cody";
              lastName = "Wright";
              groups = ["nextcloud_user" "nextcloud_admin"];
              # Password from cody's personal secrets file
              password.result = config.shb.sops.secret."cody/personal/password".result;
            };
          };

          # enforceGroups = true;  # Delete groups not declared (default: true)
          # enforceUsers = false;  # Don't delete manually created users (default: false)
        };
        # SOPS secret for cody's password (from cody's personal secrets file)
        shb.sops.secret."cody/personal/password" = {
          request = config.shb.lldap.ensureUsers.CodyWright.password.request;
          settings = {
            sopsFile = ../../users/cody/secrets.yaml;
            key = "cody/personal/password";
          };
        };
        shb.sops.secret."starcommand/selfhost/auth/lldap/admin_password".request =
          config.shb.lldap.ldapUserPassword.request;
        shb.sops.secret."starcommand/selfhost/auth/lldap/jwt_secret".request =
          config.shb.lldap.jwtSecret.request;

        # Authelia - SSO/OIDC provider
        shb.authelia = {
          enable = true;
          inherit domain;
          subdomain = authSubdomain;
          ssl = config.shb.certs.certs.selfsigned.n;
          ldapPort = config.shb.lldap.ldapPort;
          ldapHostname = "127.0.0.1";
          dcdomain = config.shb.lldap.dcdomain;

          secrets = {
            # Generated with: openssl rand -base64 64
            jwtSecret.result = config.shb.sops.secret."starcommand/selfhost/auth/authelia/jwt_secret".result;
            # Reuse LLDAP admin password for LDAP connection
            ldapAdminPassword.result =
              config.shb.sops.secret."starcommand/selfhost/auth/authelia/ldap_admin_password".result;
            # Generated with: openssl rand -base64 64
            sessionSecret.result =
              config.shb.sops.secret."starcommand/selfhost/auth/authelia/session_secret".result;
            # Generated with: openssl rand -base64 64
            storageEncryptionKey.result =
              config.shb.sops.secret."starcommand/selfhost/auth/authelia/storage_encryption_key".result;
            # Generated with: openssl rand -base64 64
            identityProvidersOIDCHMACSecret.result =
              config.shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_hmac_secret".result;
            # Generated with: openssl genrsa 4096
            identityProvidersOIDCIssuerPrivateKey.result =
              config.shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_issuer_private_key".result;
          };
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/jwt_secret".request =
          config.shb.authelia.secrets.jwtSecret.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/ldap_admin_password" = {
          request = config.shb.authelia.secrets.ldapAdminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password"; # Reuse LLDAP admin password
        };
        # Nextcloud's copy of LLDAP admin password (owned by nextcloud user)
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/ldap_admin_password" = {
          request = config.shb.nextcloud.apps.ldap.adminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password"; # Reuse same LLDAP admin password
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/session_secret".request =
          config.shb.authelia.secrets.sessionSecret.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/storage_encryption_key".request =
          config.shb.authelia.secrets.storageEncryptionKey.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_hmac_secret".request =
          config.shb.authelia.secrets.identityProvidersOIDCHMACSecret.request;
        shb.sops.secret."starcommand/selfhost/auth/authelia/oidc_issuer_private_key".request =
          config.shb.authelia.secrets.identityProvidersOIDCIssuerPrivateKey.request;

        # Nextcloud with LDAP and SSO integration
        shb.nextcloud = {
          enable = true;
          inherit domain;
          subdomain = nextcloudSubdomain;
          dataDir = "/var/lib/nextcloud";
          port = lib.mkForce null; # Use SSL
          ssl = config.shb.certs.certs.selfsigned.n;
          tracing = null;
          defaultPhoneRegion = "US";

          # Generated with: openssl rand -base64 32
          adminPass.result =
            config.shb.sops.secret."starcommand/selfhost/apps/nextcloud/admin_password".result;

          apps = {
            previewgenerator.enable = true;

            # LDAP integration
            ldap = {
              enable = true;
              host = "127.0.0.1";
              port = config.shb.lldap.ldapPort;
              dcdomain = config.shb.lldap.dcdomain;
              adminName = "admin";
              # Reuse LLDAP admin password (Nextcloud's copy with proper ownership)
              adminPassword.result =
                config.shb.sops.secret."starcommand/selfhost/apps/nextcloud/ldap_admin_password".result;
              userGroup = "nextcloud_user";
            };

            # SSO integration via Authelia
            sso = {
              enable = true;
              endpoint = "https://${authSubdomain}.${domain}";
              clientID = "nextcloud";
              fallbackDefaultAuth = true;
              # Secret for Nextcloud (owned by nextcloud user)
              secret.result = config.shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".result;
              # Shared secret for Authelia (owned by authelia user, same value via settings.key)
              secretForAuthelia.result =
                config.shb.sops.secret."starcommand/selfhost/auth/authelia/nextcloud_sso_secret".result;
            };
          };
        };
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/admin_password".request =
          config.shb.nextcloud.adminPass.request;
        # Nextcloud's copy of the SSO secret (owned by nextcloud user)
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".request =
          config.shb.nextcloud.apps.sso.secret.request;
        # Authelia's copy of the SSO secret (owned by authelia user, same value)
        shb.sops.secret."starcommand/selfhost/auth/authelia/nextcloud_sso_secret" = {
          request = config.shb.nextcloud.apps.sso.secretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/nextcloud/sso_secret"; # Use same secret value
        };

        # Local DNS resolution for homelab services
        # Disable systemd-resolved so dnsmasq can use port 53
        services.resolved.enable = false;

        services.dnsmasq = {
          enable = true;
          settings = {
            domain-needed = true;
            bogus-priv = true;
            no-resolv = true; # Don't read /etc/resolv.conf
            # Forward other DNS queries to external DNS
            server = ["1.1.1.1" "8.8.8.8"];
            address = map (hostname: "/${hostname}/127.0.0.1") [
              domain
              "${nextcloudSubdomain}.${domain}"
              "${ldapSubdomain}.${domain}"
              "${authSubdomain}.${domain}"
            ];
          };
        };

        # Nginx configuration
        shb.nginx.accessLog = lib.mkDefault true;
        shb.nginx.debugLog = lib.mkDefault false;
      };
    };
  };
}
