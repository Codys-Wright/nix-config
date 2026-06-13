# Auth stack — the SSO backbone, moved off selfhostblocks into the cluster.
#
#   lldap     lldap/lldap:v0.6.2     (LDAP :3890, web UI :17170)
#   redis     valkey/valkey:8        (Authelia session store)
#   authelia  authelia/authelia:4.39 (forward-auth + OIDC provider :9091)
#
# Faithful replica of the host shb.authelia config: access rules, the 9 OIDC
# clients, LDAP against the in-cluster lldap, pg-main storage, filesystem
# notifier. Secrets are mounted from `authelia-secrets` (host bridge) exactly
# like the host's AUTHELIA_*_FILE + {{ secret }} template setup, so 2FA and
# every existing OIDC client keep working.
#
# Public ldap./auth. Ingresses are added at the cutover (host serves them
# until then). Host bridge: <FTS.cluster/auth-bridge>.
{ ... }:
let
  lldapImage = "lldap/lldap:v0.6.2";
  autheliaImage = "authelia/authelia:4.39";

  lldapSecretEnv = key: {
    name = key;
    valueFrom.secretKeyRef = {
      name = "lldap-secrets";
      inherit key;
    };
  };

  # Authelia configuration — translated from the host shb-generated config.yml.
  # Secrets come in via *_FILE env (core) and {{ secret }} filters (jwks +
  # client secrets), mounted from authelia-secrets at /secrets.
  autheliaConfig = ''
    theme: light
    log:
      level: info
      format: json
    totp:
      issuer: auth_starcommand_live
      algorithm: sha1
      digits: 6
      period: 30
      skew: 1
      secret_size: 32
    server:
      address: tcp://0.0.0.0:9091
    session:
      name: authelia_session
      same_site: lax
      expiration: 1h
      inactivity: 5m
      remember_me: 1M
      cookies:
        - domain: starcommand.live
          authelia_url: https://auth.starcommand.live
      redis:
        host: authelia-redis
        port: 6379
    storage:
      postgres:
        address: tcp://pg-main-rw.databases.svc:5432
        database: authelia
        username: authelia
    notifier:
      filesystem:
        filename: /tmp/authelia-notifications
    authentication_backend:
      refresh_interval: 5m
      password_reset:
        disable: false
      password_change:
        disable: false
      ldap:
        implementation: lldap
        address: ldap://lldap.auth.svc:3890
        base_dn: dc=starcommand,dc=live
        user: uid=admin,ou=people,dc=starcommand,dc=live
        start_tls: false
        timeout: 5s
    access_control:
      default_policy: deny
      networks:
        - name: internal
          networks:
            - 10.0.0.0/8
            - 172.16.0.0/12
            - 192.168.0.0/18
      rules:
        - domain: auth.starcommand.live
          policy: bypass
          resources:
            - '^/api/.*'
        - domain: torrents.starcommand.live
          policy: bypass
          resources:
            - '^/json'
        - domain: torrents.starcommand.live
          policy: two_factor
          subject:
            - 'group:deluge_user'
        - domain: photos.starcommand.live
          policy: bypass
          resources:
            - '^/api.*'
            - '^/.well-known/immich'
        - domain: radarr.starcommand.live
          policy: bypass
          resources:
            - '^/api.*'
            - '^/feed.*'
        - domain: sonarr.starcommand.live
          policy: bypass
          resources:
            - '^/api.*'
            - '^/feed.*'
        - domain: bazarr.starcommand.live
          policy: bypass
          resources:
            - '^/api.*'
            - '^/feed.*'
        - domain: lidarr.starcommand.live
          policy: bypass
          resources:
            - '^/api.*'
            - '^/feed.*'
        - domain: jackett.starcommand.live
          policy: bypass
          resources:
            - '^/api.*'
            - '^/feed.*'
        - domain:
            - radarr.starcommand.live
            - sonarr.starcommand.live
            - bazarr.starcommand.live
            - lidarr.starcommand.live
            - jackett.starcommand.live
          policy: two_factor
          subject:
            - 'group:arr_user'
        - domain: youtube.starcommand.live
          policy: one_factor
          subject:
            - 'group:pinchflat_user'
        - domain: finance.starcommand.live
          policy: two_factor
          subject:
            - 'group:hledger_user'
        - domain:
            - agent.starcommand.live
            - workspace.starcommand.live
            - hermes.starcommand.live
          policy: one_factor
          subject:
            - 'group:hermes_user'
        - domain: chat.starcommand.live
          policy: one_factor
          subject:
            - 'group:open-webui_user'
        - domain: jdownloader.starcommand.live
          policy: two_factor
          subject:
            - 'group:jdownloader_user'
        - domain: dokploy.starcommand.live
          policy: two_factor
          subject:
            - 'group:dokploy_admin'
        - domain: '*.starcommand.live'
          policy: two_factor
          subject:
            - 'group:nextcloud_user'
            - 'group:jellyfin_user'
            - 'group:grocy_user'
            - 'group:arr_user'
            - 'group:lldap_admin'
            - 'group:vaultwarden_admin'
            - 'group:grafana_user'
            - 'group:forgejo_user'
            - 'group:karakeep_user'
            - 'group:audiobookshelf_user'
            - 'group:hledger_user'
            - 'group:homeassistant_user'
            - 'group:pinchflat_user'
            - 'group:immich_user'
    identity_providers:
      oidc:
        jwks:
          - key: {{ secret "/secrets/oidc_issuer_private_key" | mindent 10 "|" | msquote }}
        claims_policies:
          default:
            id_token:
              - email
              - preferred_username
              - name
              - groups
        clients:
          - client_id: grafana
            client_name: Grafana
            client_secret: '{{ secret "/secrets/grafana_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            require_pkce: true
            pkce_challenge_method: S256
            redirect_uris:
              - https://grafana.starcommand.live/login/generic_oauth
            scopes:
              - openid
              - email
              - profile
              - groups
            token_endpoint_auth_method: client_secret_basic
          - client_id: nextcloud
            client_name: Nextcloud
            client_secret: '{{ secret "/secrets/nextcloud_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            require_pkce: true
            pkce_challenge_method: S256
            redirect_uris:
              - https://cloud.starcommand.live/index.php/apps/user_oidc/code
              - https://cloud.starcommand.live/apps/user_oidc/code
            scopes:
              - openid
              - profile
              - email
              - groups
            token_endpoint_auth_method: client_secret_post
          - client_id: forgejo
            client_name: Forgejo
            client_secret: '{{ secret "/secrets/forgejo_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            redirect_uris:
              - https://git.starcommand.live/user/oauth2/SHB-Authelia/callback
            scopes:
              - openid
              - email
              - profile
              - groups
          - client_id: immich
            client_name: Immich
            client_secret: '{{ secret "/secrets/immich_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            redirect_uris:
              - https://photos.starcommand.live/auth/login
              - https://photos.starcommand.live/user-settings
              - app.immich:///oauth-callback
            scopes:
              - openid
              - email
              - profile
              - groups
            token_endpoint_auth_method: client_secret_post
          - client_id: karakeep
            client_name: Karakeep
            client_secret: '{{ secret "/secrets/karakeep_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            redirect_uris:
              - https://bookmarks.starcommand.live/api/auth/callback/custom
            scopes:
              - openid
              - email
              - profile
          - client_id: jellyfin
            client_name: Jellyfin
            client_secret: '{{ secret "/secrets/jellyfin_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            require_pkce: true
            pkce_challenge_method: S256
            redirect_uris:
              - https://media.starcommand.live/sso/OID/r/Authelia
              - https://media.starcommand.live/sso/OID/redirect/Authelia
            scopes:
              - openid
              - profile
              - email
              - groups
            token_endpoint_auth_method: client_secret_post
            userinfo_signed_response_alg: none
          - client_id: audiobookshelf
            client_name: Audiobookshelf
            client_secret: '{{ secret "/secrets/audiobookshelf_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            require_pkce: true
            pkce_challenge_method: S256
            redirect_uris:
              - https://audiobooks.starcommand.live/auth/openid/callback
              - https://audiobooks.starcommand.live/auth/openid/mobile-redirect
            scopes:
              - openid
              - profile
              - email
              - groups
            token_endpoint_auth_method: client_secret_basic
            userinfo_signed_response_alg: none
          - client_id: argocd
            client_name: Argo CD
            client_secret: '{{ secret "/secrets/argocd_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            redirect_uris:
              - https://argocd.starcommand.live/auth/callback
              - http://localhost:8085/auth/callback
            scopes:
              - openid
              - email
              - profile
              - groups
            token_endpoint_auth_method: client_secret_basic
            userinfo_signed_response_alg: none
          - client_id: open-webui
            client_name: Open WebUI
            client_secret: '{{ secret "/secrets/open-webui_client_secret" }}'
            public: false
            authorization_policy: one_factor
            claims_policy: default
            redirect_uris:
              - https://chat.starcommand.live/oauth/oidc/callback
            scopes:
              - openid
              - email
              - profile
              - groups
            token_endpoint_auth_method: client_secret_basic
  '';

  autheliaSecretFileEnv = [
    {
      name = "X_AUTHELIA_CONFIG_FILTERS";
      value = "template";
    }
    {
      name = "AUTHELIA_SESSION_SECRET_FILE";
      value = "/secrets/session_secret";
    }
    {
      name = "AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE";
      value = "/secrets/storage_encryption_key";
    }
    {
      name = "AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE";
      value = "/secrets/jwt_secret";
    }
    {
      name = "AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE";
      value = "/secrets/oidc_hmac_secret";
    }
    {
      name = "AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE";
      value = "/secrets/ldap_admin_password";
    }
    {
      name = "AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE";
      value = "/secrets/db_password";
    }
  ];
in
{
  applications.auth = {
    namespace = "auth";
    createNamespace = true;

    resources = {
      configMaps.authelia-config.data."configuration.yml" = autheliaConfig;

      persistentVolumeClaims."lldap-data".spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "db-local";
        resources.requests.storage = "1Gi";
      };

      deployments = {
        lldap.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "lldap";
          template = {
            metadata.labels.app = "lldap";
            spec = {
              enableServiceLinks = false;
              nodeSelector."kubernetes.io/hostname" = "starcommand";
              # The image ships a default lldap_config.toml with an ACTIVE
              # placeholder `key_seed`, which conflicts with the migrated
              # server_key file (where the host's OPAQUE passwords are anchored)
              # and makes LLDAP refuse to start ("private key has changed").
              # Overwrite it each boot with a clean, seedless config that pins
              # the key to the migrated file. Idempotent; survives PVC/pod
              # recreation.
              initContainers.seed-config = {
                image = lldapImage;
                command = [
                  "sh"
                  "-c"
                  ''
                    cat > /data/lldap_config.toml <<'EOF'
                    database_url = "sqlite:///data/users.db?mode=rwc"
                    ldap_base_dn = "dc=starcommand,dc=live"
                    key_file = "/data/server_key"
                    EOF
                  ''
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/data";
                  }
                ];
              };
              containers.lldap = {
                image = lldapImage;
                ports = {
                  ldap.containerPort = 3890;
                  web.containerPort = 17170;
                };
                env = [
                  {
                    name = "LLDAP_LDAP_BASE_DN";
                    value = "dc=starcommand,dc=live";
                  }
                  {
                    name = "LLDAP_DATABASE_URL";
                    value = "sqlite:///data/users.db?mode=rwc";
                  }
                  {
                    name = "LLDAP_HTTP_HOST";
                    value = "0.0.0.0";
                  }
                  {
                    name = "LLDAP_LDAP_HOST";
                    value = "0.0.0.0";
                  }
                  (lldapSecretEnv "LLDAP_JWT_SECRET")
                  (lldapSecretEnv "LLDAP_LDAP_USER_PASS")
                ];
                volumeMounts = [
                  {
                    name = "data";
                    mountPath = "/data";
                  }
                ];
              };
              volumes = [
                {
                  name = "data";
                  persistentVolumeClaim.claimName = "lldap-data";
                }
              ];
            };
          };
        };

        authelia-redis.spec = {
          replicas = 1;
          selector.matchLabels.app = "authelia-redis";
          template = {
            metadata.labels.app = "authelia-redis";
            spec = {
              enableServiceLinks = false;
              nodeSelector."kubernetes.io/hostname" = "starcommand";
              containers.redis = {
                image = "valkey/valkey:8";
                ports.redis.containerPort = 6379;
              };
            };
          };
        };

        authelia.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "authelia";
          template = {
            metadata.labels.app = "authelia";
            spec = {
              enableServiceLinks = false;
              nodeSelector."kubernetes.io/hostname" = "starcommand";
              containers.authelia = {
                image = autheliaImage;
                # No args override — the image's default command already loads
                # /config/configuration.yml (where the ConfigMap is mounted);
                # overriding it trips the image's entrypoint wrapper.
                ports.http.containerPort = 9091;
                env = autheliaSecretFileEnv;
                volumeMounts = [
                  {
                    name = "config";
                    mountPath = "/config";
                  }
                  {
                    name = "secrets";
                    mountPath = "/secrets";
                    readOnly = true;
                  }
                ];
              };
              volumes = [
                {
                  name = "config";
                  configMap.name = "authelia-config";
                }
                {
                  name = "secrets";
                  secret.secretName = "authelia-secrets";
                }
              ];
            };
          };
        };
      };

      services = {
        lldap.spec = {
          selector.app = "lldap";
          ports = {
            ldap = {
              port = 3890;
              targetPort = 3890;
            };
            web = {
              port = 17170;
              targetPort = 17170;
            };
          };
        };
        authelia-redis.spec = {
          selector.app = "authelia-redis";
          ports.redis.port = 6379;
        };
        authelia.spec = {
          selector.app = "authelia";
          ports.http = {
            port = 80;
            targetPort = 9091;
          };
        };
      };

      ingresses = {
        authelia = {
          metadata.annotations."external-dns.alpha.kubernetes.io/target" =
            (import ../lib/constants.nix).tunnelTarget;
          spec = {
            ingressClassName = "traefik";
            rules = [
              {
                host = "auth.starcommand.live";
                http.paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend.service = {
                      name = "authelia";
                      port.number = 80;
                    };
                  }
                ];
              }
            ];
          };
        };
        lldap = {
          metadata.annotations."external-dns.alpha.kubernetes.io/target" =
            (import ../lib/constants.nix).tunnelTarget;
          spec = {
            ingressClassName = "traefik";
            rules = [
              {
                host = "ldap.starcommand.live";
                http.paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend.service = {
                      name = "lldap";
                      port.number = 17170;
                    };
                  }
                ];
              }
            ];
          };
        };
      };
    };
  };
}
