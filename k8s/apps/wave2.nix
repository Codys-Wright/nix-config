# Wave 2 migrations: karakeep (+ meilisearch + chrome) and jellyfin.
# Host-side counterpart: starcommand <FTS.cluster/wave2-bridge>.
{ lib, ... }:
let
  mkSimpleApp = import ../lib/simple-app.nix;
  tz = {
    name = "TZ";
    value = "America/Chicago";
  };
  # same paths as on the host: jellyfin's library DB stores absolute paths
  mediaMount = name: sub: {
    inherit name;
    path = "/mnt/storage/Operations/media/${sub}";
    mountPath = "/mnt/storage/Operations/media/${sub}";
  };
in
lib.mkMerge [
  # Jellyfin — own auth (LDAP + SSO plugins travel in the migrated state).
  # LDAP plugin is re-pointed at 10.10.10.1:3890 during data migration.
  (mkSimpleApp {
    name = "jellyfin";
    host = "media.starcommand.live";
    image = "jellyfin/jellyfin:10.11.11";
    port = 8096;
    state = {
      mountPath = "/config";
      size = "20Gi";
    };
    nfsMounts = [
      (mediaMount "movies" "movies")
      (mediaMount "tv" "tv")
      (mediaMount "music" "music")
      (mediaMount "audiobooks" "audiobooks")
      {
        name = "youtube";
        path = "/mnt/storage/Operations/youtube";
        mountPath = "/mnt/storage/Operations/youtube";
      }
    ];
    env = [
      tz
      {
        name = "JELLYFIN_PublishedServerUrl";
        value = "https://media.starcommand.live";
      }
    ];
  })

  # Karakeep — app + chrome (crawler) + meilisearch (search).
  {
    applications.karakeep = {
      namespace = "selfhost";

      resources = {
        persistentVolumeClaims = {
          "karakeep-state".spec = {
            accessModes = [ "ReadWriteMany" ];
            storageClassName = "nas-nfs";
            resources.requests.storage = "10Gi";
          };
          "meilisearch-state".spec = {
            accessModes = [ "ReadWriteMany" ];
            storageClassName = "nas-nfs";
            resources.requests.storage = "5Gi";
          };
        };

        deployments = {
          karakeep.spec = {
            replicas = 1;
            strategy.type = "Recreate";
            selector.matchLabels.app = "karakeep";
            template = {
              metadata.labels.app = "karakeep";
              spec = {
                enableServiceLinks = false;
                containers.karakeep = {
                  image = "ghcr.io/karakeep-app/karakeep:release";
                  ports.http.containerPort = 3000;
                  env = [
                    tz
                    {
                      name = "DATA_DIR";
                      value = "/data";
                    }
                    {
                      name = "NEXTAUTH_URL";
                      value = "https://bookmarks.starcommand.live";
                    }
                    {
                      name = "BROWSER_WEB_URL";
                      value = "http://chrome:9222";
                    }
                    {
                      name = "MEILI_ADDR";
                      value = "http://meilisearch:7700";
                    }
                    {
                      name = "DISABLE_PASSWORD_AUTH";
                      value = "true";
                    }
                    # was false under shb, but the OIDC-level group gate
                    # (authorization policy) is gone — closed signups instead;
                    # existing accounts are in the migrated DB
                    {
                      name = "DISABLE_SIGNUPS";
                      value = "true";
                    }
                    {
                      name = "OAUTH_WELLKNOWN_URL";
                      value = "https://auth.starcommand.live/.well-known/openid-configuration";
                    }
                    {
                      name = "OAUTH_CLIENT_ID";
                      value = "karakeep";
                    }
                    {
                      name = "OAUTH_PROVIDER_NAME";
                      value = "Authelia";
                    }
                    {
                      name = "NEXTAUTH_SECRET";
                      valueFrom.secretKeyRef = {
                        name = "karakeep-secrets";
                        key = "nextauth-secret";
                      };
                    }
                    {
                      name = "MEILI_MASTER_KEY";
                      valueFrom.secretKeyRef = {
                        name = "karakeep-secrets";
                        key = "meili-master-key";
                      };
                    }
                    {
                      name = "OAUTH_CLIENT_SECRET";
                      valueFrom.secretKeyRef = {
                        name = "karakeep-secrets";
                        key = "oauth-client-secret";
                      };
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "state";
                      mountPath = "/data";
                    }
                  ];
                };
                volumes = [
                  {
                    name = "state";
                    persistentVolumeClaim.claimName = "karakeep-state";
                  }
                ];
              };
            };
          };

          chrome.spec = {
            replicas = 1;
            selector.matchLabels.app = "chrome";
            template = {
              metadata.labels.app = "chrome";
              spec = {
                enableServiceLinks = false;
                containers.chrome = {
                  image = "gcr.io/zenika-hub/alpine-chrome:124";
                  ports.cdp.containerPort = 9222;
                  args = [
                    "--no-sandbox"
                    "--disable-gpu"
                    "--disable-dev-shm-usage"
                    "--remote-debugging-address=0.0.0.0"
                    "--remote-debugging-port=9222"
                    "--hide-scrollbars"
                  ];
                };
              };
            };
          };

          meilisearch.spec = {
            replicas = 1;
            strategy.type = "Recreate";
            selector.matchLabels.app = "meilisearch";
            template = {
              metadata.labels.app = "meilisearch";
              spec = {
                enableServiceLinks = false;
                containers.meilisearch = {
                  image = "getmeili/meilisearch:v1.13";
                  ports.http.containerPort = 7700;
                  env = [
                    {
                      name = "MEILI_NO_ANALYTICS";
                      value = "true";
                    }
                    {
                      name = "MEILI_EXPERIMENTAL_DUMPLESS_UPGRADE";
                      value = "true";
                    }
                    {
                      name = "MEILI_MASTER_KEY";
                      valueFrom.secretKeyRef = {
                        name = "karakeep-secrets";
                        key = "meili-master-key";
                      };
                    }
                  ];
                  volumeMounts = [
                    {
                      name = "state";
                      mountPath = "/meili_data";
                    }
                  ];
                };
                volumes = [
                  {
                    name = "state";
                    persistentVolumeClaim.claimName = "meilisearch-state";
                  }
                ];
              };
            };
          };
        };

        services = {
          karakeep.spec = {
            selector.app = "karakeep";
            ports.http.port = 80;
            ports.http.targetPort = 3000;
          };
          chrome.spec = {
            selector.app = "chrome";
            ports.cdp.port = 9222;
          };
          meilisearch.spec = {
            selector.app = "meilisearch";
            ports.http.port = 7700;
          };
        };

        ingresses.karakeep = {
          metadata.annotations."external-dns.alpha.kubernetes.io/target" =
            (import ../lib/constants.nix).tunnelTarget;
          spec = {
            ingressClassName = "traefik";
            rules = [
              {
                host = "bookmarks.starcommand.live";
                http.paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend.service = {
                      name = "karakeep";
                      port.number = 80;
                    };
                  }
                ];
              }
            ];
          };
        };
      };
    };
  }
]
