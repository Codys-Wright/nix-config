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
      grocySubdomain = "grocy";
      delugeSubdomain = "torrents";
      forgejoSubdomain = "git";
      karakeepSubdomain = "bookmarks";
      audiobookshelfSubdomain = "audiobooks";
      hledgerSubdomain = "finance";
      homeAssistantSubdomain = "home";
      openWebuiSubdomain = "chat";
      pinchflatSubdomain = "youtube";
      immichSubdomain = "photos";

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
            {
              hostname = "grocy.${domain}"; # Grocy
              service = "https://localhost";
            }
            {
              hostname = "torrents.${domain}"; # Deluge
              service = "https://localhost";
            }
            {
              hostname = "git.${domain}"; # Forgejo
              service = "https://localhost";
            }
            {
              hostname = "bookmarks.${domain}"; # Karakeep
              service = "https://localhost";
            }
            {
              hostname = "audiobooks.${domain}"; # Audiobookshelf
              service = "https://localhost";
            }
            {
              hostname = "finance.${domain}"; # Hledger
              service = "https://localhost";
            }
            {
              hostname = "home.${domain}"; # Home-Assistant
              service = "https://localhost";
            }
            {
              hostname = "chat.${domain}"; # Open-WebUI
              service = "https://localhost";
            }
            {
              hostname = "youtube.${domain}"; # Pinchflat
              service = "https://localhost";
            }
            {
              hostname = "photos.${domain}"; # Immich
              service = "https://localhost";
            }
            {
              hostname = "radarr.${domain}"; # Radarr
              service = "https://localhost";
            }
            {
              hostname = "sonarr.${domain}"; # Sonarr
              service = "https://localhost";
            }
            {
              hostname = "bazarr.${domain}"; # Bazarr
              service = "https://localhost";
            }
            {
              hostname = "readarr.${domain}"; # Readarr
              service = "https://localhost";
            }
            {
              hostname = "lidarr.${domain}"; # Lidarr
              service = "https://localhost";
            }
            {
              hostname = "jackett.${domain}"; # Jackett
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
            # New service groups
            forgejo_user = {};
            forgejo_admin = {};
            karakeep_user = {};
            audiobookshelf_user = {};
            audiobookshelf_admin = {};
            hledger_user = {};
            homeassistant_user = {};
            open-webui_user = {};
            open-webui_admin = {};
            pinchflat_user = {};
            immich_user = {};
            immich_admin = {};
            grocy_user = {};
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
              passwordSopsFile = ../../users/cody/secrets.yaml;
            };

             amy = {
               email = "amy.wright@example.com"; # TODO: Update with real email
               firstName = "Amy";
               lastName = "Wright";
               groups = [
                 "nextcloud_user"
                 "jellyfin_user"
                 "grocy_user"
               ];
               passwordKey = "starcommand/selfhost/users/amy/password";
               passwordSopsFile = ../../users/starcommand/secrets.yaml;
             };

             tommy = {
               email = "tommy.wright@example.com"; # TODO: Update with real email
               firstName = "Tommy";
               lastName = "Wright";
               groups = [
                 "nextcloud_user"
                 "jellyfin_user"
                 "grocy_user"
               ];
               passwordKey = "starcommand/selfhost/users/tommy/password";
               passwordSopsFile = ../../users/starcommand/secrets.yaml;
             };

             bri = {
               email = "bri.zacharias@example.com"; # TODO: Update with real email
               firstName = "Bri";
               lastName = "Zacharias";
               groups = [
                 "nextcloud_user"
                 "jellyfin_user"
                 "grocy_user"
               ];
               passwordKey = "starcommand/selfhost/users/bri/password";
               passwordSopsFile = ../../users/starcommand/secrets.yaml;
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
          # App/config stays on btrfs for proper permissions
          dataDir = "/var/lib/nextcloud";
          adminPasswordKey = "starcommand/selfhost/apps/nextcloud/admin_password";

          # External Storage - merged storage and Synology NAS
          externalStorage = {
            userLocalMount = {
              directory = "/mnt/storage";
              mountName = "storage"; # Appears as "storage" folder in Nextcloud
            };
            localMounts = {
              synologyMedia = {
                directory = "/mnt/synology-vault";
                mountName = "synology-media"; # Appears as "synology-media" folder in Nextcloud
              };
            };
          };

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
        # NOTE: Media libraries must be configured via web UI at https://media.starcommand.live
        # Recommended library paths (pre-created on /mnt/storage):
        #   Movies: /mnt/storage/media/movies
        #   TV Shows: /mnt/storage/media/tv
        #   Music: /mnt/storage/media/music
        #   Audiobooks: /mnt/storage/media/audiobooks
        # See docs/jellyfin-setup.md for detailed setup instructions
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

        # Grocy - Grocery and household management
        (FTS.selfhost._.grocy {
          inherit domain;
          subdomain = grocySubdomain;
          currency = "USD";
          culture = "en";
        })

        # Deluge - BitTorrent client
        (FTS.selfhost._.deluge {
          inherit domain;
          subdomain = delugeSubdomain;
          downloadLocation = "/mnt/storage/torrents"; # Torrents on merged storage
          localclientPasswordKey = "starcommand/selfhost/apps/deluge/localclient_password";
          prometheusScraperPasswordKey = "starcommand/selfhost/apps/deluge/prometheus_scraper_password";
          authEndpoint = "https://${authSubdomain}.${domain}";
        })

        # Forgejo - Git hosting
        (FTS.selfhost._.forgejo {
          inherit domain;
          subdomain = forgejoSubdomain;
          databasePasswordKey = "starcommand/selfhost/apps/forgejo/database_password";
          # LDAP
          ldapDcdomain = "dc=${builtins.replaceStrings ["."] [",dc="] domain}";
          ldapAdminPasswordKey = "starcommand/selfhost/apps/forgejo/ldap_admin_password";
          ldapUserGroup = "forgejo_user";
          ldapAdminGroup = "forgejo_admin";
          # SSO
          authEndpoint = "https://${authSubdomain}.${domain}";
          ssoSecretKey = "starcommand/selfhost/apps/forgejo/sso_secret";
          ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/forgejo_sso_secret";
        })

        # Karakeep - AI-powered bookmarking
        (FTS.selfhost._.karakeep {
          inherit domain;
          subdomain = karakeepSubdomain;
          nextauthSecretKey = "starcommand/selfhost/apps/karakeep/nextauth_secret";
          meilisearchMasterKeyKey = "starcommand/selfhost/apps/karakeep/meilisearch_master_key";
          # SSO
          authEndpoint = "https://${authSubdomain}.${domain}";
          ssoSecretKey = "starcommand/selfhost/apps/karakeep/sso_secret";
          ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/karakeep_sso_secret";
        })

        # Audiobookshelf - Audiobook server
        (FTS.selfhost._.audiobookshelf {
          inherit domain;
          subdomain = audiobookshelfSubdomain;
          # SSO
          authEndpoint = "https://${authSubdomain}.${domain}";
          ssoSecretKey = "starcommand/selfhost/apps/audiobookshelf/sso_secret";
          ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/audiobookshelf_sso_secret";
        })

        # Hledger - Plain-text accounting
        (FTS.selfhost._.hledger {
          inherit domain;
          subdomain = hledgerSubdomain;
          authEndpoint = "https://${authSubdomain}.${domain}";
        })

        # Home-Assistant - Home automation
        (FTS.selfhost._.home-assistant {
          inherit domain;
          subdomain = homeAssistantSubdomain;
          name = "Star Command Home";
          country = "US";
          latitude = "0.0";
          longitude = "0.0";
          time_zone = "America/Chicago";
          unit_system = "us_customary";
          ldap = {
            userGroup = "homeassistant_user";
          };
        })

        # Open-WebUI - LLM chat interface
        (FTS.selfhost._.open-webui {
          inherit domain;
          subdomain = openWebuiSubdomain;
          # SSO
          authEndpoint = "https://${authSubdomain}.${domain}";
          ssoSecretKey = "starcommand/selfhost/apps/open-webui/sso_secret";
          ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/open-webui_sso_secret";
        })

        # Pinchflat - YouTube downloader
        # NOTE: Videos saved to /mnt/storage/youtube
        # To watch in Jellyfin: Add /mnt/storage/youtube as a library
        # Or configure Pinchflat via web UI to save to specific Jellyfin folders:
        #   - Music videos → /mnt/storage/media/music
        #   - Documentaries → /mnt/storage/media/movies
        #   - Podcasts → /mnt/storage/media/tv
        (FTS.selfhost._.pinchflat {
          inherit domain;
          subdomain = pinchflatSubdomain;
          mediaDir = "/mnt/storage/youtube"; # Downloaded videos on merged storage
          timeZone = "America/Chicago";
          secretKeyBaseKey = "starcommand/selfhost/apps/pinchflat/secret_key_base";
          sso = {
            authEndpoint = "https://${authSubdomain}.${domain}";
          };
        })

        # Immich - Photo and video backup
        (FTS.selfhost._.immich {
          inherit domain;
          subdomain = immichSubdomain;
          # App state on btrfs, photos on merged storage
          mediaLocation = "/mnt/storage/photos"; # Photo library on merged storage
          # SSO
          authEndpoint = "https://${authSubdomain}.${domain}";
          ssoSecretKey = "starcommand/selfhost/apps/immich/sso_secret";
          ssoSecretForAutheliaKey = "starcommand/selfhost/auth/authelia/immich_sso_secret";
        })

        # ProtonVPN - VPN service with kill switch
        (FTS.selfhost._.protonvpn {
          inherit domain;
          usernameKey = "starcommand/selfhost/openvpn/username";
          passwordKey = "starcommand/selfhost/openvpn/password";
          killswitch = {
            enable = true;
            allowedSubnets = [
              "192.168.0.0/16"
              "10.0.0.0/8"
            ];
            allowedIPs = [
              "192.168.0.114" # Synology NAS
            ];
            exemptPorts = [22];
          };
        })

        # Samba Client Tools - SMB/CIFS utilities for network shares
        (FTS.selfhost._.samba-client {})
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
            sopsFile = ../../users/cody/secrets.yaml;
            key = "cody/personal/password";
          };
        };

        # SOPS secrets for new users
        shb.sops.secret."starcommand/selfhost/users/amy/password" = {
          request = config.shb.lldap.ensureUsers.amy.password.request;
          settings.key = "starcommand/selfhost/users/amy/password";
        };

        shb.sops.secret."starcommand/selfhost/users/tommy/password" = {
          request = config.shb.lldap.ensureUsers.tommy.password.request;
          settings.key = "starcommand/selfhost/users/tommy/password";
        };

        shb.sops.secret."starcommand/selfhost/users/bri/password" = {
          request = config.shb.lldap.ensureUsers.bri.password.request;
          settings.key = "starcommand/selfhost/users/bri/password";
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
      };
    };
  };
}
