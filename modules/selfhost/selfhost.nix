# Self-hosting services coordination module using SelfHostBlocks
{
  inputs,
  lib,
  fleet,
  ...
}:
let
  inherit (import ./_data/vars.nix) domain;
in
{
  fleet.selfhost = {
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

    includes = [
      fleet.selfhost._.stack-core
      fleet.selfhost._.stack-auth
      fleet.selfhost._.stack-media
      fleet.selfhost._.stack-productivity
      fleet.selfhost._.stack-network
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # Import SelfHostBlocks modules
        # default imports everything except sops
        imports = [
          inputs.selfhostblocks.nixosModules.default
          inputs.selfhostblocks.nixosModules.sops
          inputs.sops-nix.nixosModules.default
        ];

        # SOPS configuration - points to starcommand user secrets
        sops = {
          defaultSopsFile = lib.mkDefault "${inputs.nix-secrets}/sops/users/starcommand.yaml";
          # store-path sops file (flake input) — not validatable at eval time
          validateSopsFiles = false;
          # Use host's SSH key for decryption during build
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };

        # Nginx reverse proxy
        shb.nginx.accessLog = lib.mkDefault true;
        shb.nginx.debugLog = lib.mkDefault false;

        # Local DNS for services to reach each other via their public hostnames
        # This allows Forgejo, etc. to reach Authelia locally instead of going through Cloudflare
        networking.hosts."127.0.0.1" = [
          "auth.${domain}"
          "ldap.${domain}"
        ];

        # SOPS secret for codywright's password (from cody's personal secrets file)
        # This needs to be in the parent module to avoid circular dependency
        shb.sops.secret."cody/personal/password" = {
          request = config.shb.lldap.ensureUsers.codywright.password.request;
          settings = {
            sopsFile = "${inputs.nix-secrets}/sops/users/cody.yaml";
            key = "cody/personal/password";
          };
        };

        # SOPS secrets for new users
        shb.sops.secret."starcommand/selfhost/users/amy_wright/password" = {
          request = config.shb.lldap.ensureUsers.amywright.password.request;
          settings.key = "starcommand/selfhost/users/amy_wright/password";
        };

        shb.sops.secret."starcommand/selfhost/users/tommy_wright/password" = {
          request = config.shb.lldap.ensureUsers.tommywright.password.request;
          settings.key = "starcommand/selfhost/users/tommy_wright/password";
        };

        shb.sops.secret."starcommand/selfhost/users/bri_zacharias/password" = {
          request = config.shb.lldap.ensureUsers.brizacharias.password.request;
          settings.key = "starcommand/selfhost/users/bri_zacharias/password";
        };

        # Secret sharing configuration
        # Set up secrets that need to be shared between services

        # Authelia LDAP admin password - reuse LLDAP admin password
        shb.sops.secret."starcommand/selfhost/auth/authelia/ldap_admin_password".settings.key =
          "starcommand/selfhost/auth/lldap/admin_password";

        # Nextcloud LDAP admin password - reuse LLDAP admin password
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/ldap_admin_password" = {
          request = config.shb.nextcloud.apps.ldap.adminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password";
        };

        # Nextcloud SSO secret
        shb.sops.secret."starcommand/selfhost/apps/nextcloud/sso_secret".request =
          config.shb.nextcloud.apps.sso.secret.request;

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

        # ============================================
        # NEW SERVICE SECRETS
        # ============================================

        # Deluge secrets
        # Forgejo secrets
        shb.sops.secret."starcommand/selfhost/apps/forgejo/database_password" = {
          request = config.shb.forgejo.databasePassword.request;
          settings = {
            key = "starcommand/selfhost/apps/forgejo/database_password";
            owner = "forgejo";
            group = "forgejo";
            mode = "0440";
          };
        };

        # Forgejo LDAP admin password - reuse LLDAP admin password
        shb.sops.secret."starcommand/selfhost/apps/forgejo/ldap_admin_password" = {
          request = config.shb.forgejo.ldap.adminPassword.request;
          settings.key = "starcommand/selfhost/auth/lldap/admin_password";
        };

        # Forgejo SSO secrets
        shb.sops.secret."starcommand/selfhost/apps/forgejo/sso_secret" = {
          request = config.shb.forgejo.sso.sharedSecret.request;
          settings.key = "starcommand/selfhost/apps/forgejo/sso_secret";
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/forgejo_sso_secret" = {
          request = config.shb.forgejo.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/forgejo/sso_secret";
        };

        # Karakeep secrets
        shb.sops.secret."starcommand/selfhost/apps/karakeep/nextauth_secret" = {
          request = config.shb.karakeep.nextauthSecret.request;
          settings.key = "starcommand/selfhost/apps/karakeep/nextauth_secret";
        };
        shb.sops.secret."starcommand/selfhost/apps/karakeep/meilisearch_master_key" = {
          request = config.shb.karakeep.meilisearchMasterKey.request;
          settings.key = "starcommand/selfhost/apps/karakeep/meilisearch_master_key";
        };
        shb.sops.secret."starcommand/selfhost/apps/karakeep/sso_secret" = {
          request = config.shb.karakeep.sso.sharedSecret.request;
          settings.key = "starcommand/selfhost/apps/karakeep/sso_secret";
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/karakeep_sso_secret" = {
          request = config.shb.karakeep.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/karakeep/sso_secret";
        };

        # Audiobookshelf SSO secrets
        shb.sops.secret."starcommand/selfhost/apps/audiobookshelf/sso_secret" = {
          request = config.shb.audiobookshelf.sso.sharedSecret.request;
          settings.key = "starcommand/selfhost/apps/audiobookshelf/sso_secret";
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/audiobookshelf_sso_secret" = {
          request = config.shb.audiobookshelf.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/audiobookshelf/sso_secret";
        };

        # Open-WebUI SSO secrets
        shb.sops.secret."starcommand/selfhost/apps/open-webui/sso_secret" = {
          request = config.shb.open-webui.sso.sharedSecret.request;
          settings.key = "starcommand/selfhost/apps/open-webui/sso_secret";
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/open-webui_sso_secret" = {
          request = config.shb.open-webui.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/open-webui/sso_secret";
        };

        # Pinchflat secrets
        shb.sops.secret."starcommand/selfhost/apps/pinchflat/secret_key_base" = {
          request = config.shb.pinchflat.secretKeyBase.request;
          settings = {
            key = "starcommand/selfhost/apps/pinchflat/secret_key_base";
            owner = "pinchflat";
            group = "pinchflat";
            mode = "0440";
          };
        };

        # Immich SSO secrets
        shb.sops.secret."starcommand/selfhost/apps/immich/sso_secret" = {
          request = config.shb.immich.sso.sharedSecret.request;
          settings = {
            key = "starcommand/selfhost/apps/immich/sso_secret";
            owner = "immich";
            group = "immich";
            mode = "0440";
          };
        };
        shb.sops.secret."starcommand/selfhost/auth/authelia/immich_sso_secret" = {
          request = config.shb.immich.sso.sharedSecretForAuthelia.request;
          settings.key = "starcommand/selfhost/apps/immich/sso_secret";
        };

        # ProtonVPN credentials
        shb.sops.secret."starcommand/selfhost/openvpn/username" = {
          settings = {
            key = "starcommand/selfhost/openvpn/username";
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };
        shb.sops.secret."starcommand/selfhost/openvpn/password" = {
          settings = {
            key = "starcommand/selfhost/openvpn/password";
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };

        # ProtonVPN remote server IP
        shb.vpn.protonvpn.remoteServerIP = "149.40.62.62";
      };
  };
}
