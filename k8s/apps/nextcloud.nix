# Nextcloud (wave 4) — official docker image, raw Deployment for full control.
# Starts on 31-apache (matches the migrated data); bump `image` to 32/33 and
# the entrypoint auto-runs `occ upgrade` on container start (one major at a
# time). Authelia via the official user_oidc app (configured post-migration).
#
# config.php is seeded ONCE from a bridge-rendered Secret (preserves
# instanceid/secret/passwordsalt) into the writable html PVC; Nextcloud owns
# it thereafter (upgrades rewrite the version field there).
# Host bridge: <FTS.cluster/nextcloud-bridge>.
{ ... }:
let
  image = "nextcloud:33-apache";
in
{
  applications.nextcloud = {
    namespace = "nextcloud";
    createNamespace = true;

    resources = {
      persistentVolumeClaims."nextcloud-html".spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "db-local";
        resources.requests.storage = "20Gi";
      };

      deployments = {
        nextcloud-redis.spec = {
          replicas = 1;
          selector.matchLabels.app = "nextcloud-redis";
          template = {
            metadata.labels.app = "nextcloud-redis";
            spec = {
              enableServiceLinks = false;
              containers.redis = {
                image = "valkey/valkey:8";
                ports.redis.containerPort = 6379;
              };
            };
          };
        };

        nextcloud.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "nextcloud";
          template = {
            metadata.labels.app = "nextcloud";
            spec = {
              enableServiceLinks = false;
              # Seed config.php into the html PVC on first boot only.
              initContainers.seed-config = {
                inherit image;
                command = [
                  "sh"
                  "-c"
                  ''
                    if [ ! -f /var/www/html/config/config.php ]; then
                      mkdir -p /var/www/html/config
                      cp /seed/config.php /var/www/html/config/config.php
                      echo "seeded config.php"
                    else
                      echo "config.php already present; leaving it"
                    fi
                  ''
                ];
                volumeMounts = [
                  {
                    name = "html";
                    mountPath = "/var/www/html";
                  }
                  {
                    name = "seed";
                    mountPath = "/seed";
                  }
                ];
              };
              containers.nextcloud = {
                inherit image;
                ports.http.containerPort = 80;
                env = [
                  {
                    name = "NEXTCLOUD_TRUSTED_DOMAINS";
                    value = "cloud.starcommand.live cloud.fasttrackaudio.com";
                  }
                  {
                    name = "PHP_MEMORY_LIMIT";
                    value = "1024M";
                  }
                  {
                    name = "PHP_UPLOAD_LIMIT";
                    value = "16G";
                  }
                ];
                volumeMounts = [
                  {
                    name = "html";
                    mountPath = "/var/www/html";
                  }
                  {
                    name = "data";
                    mountPath = "/mnt/storage/Operations/nextcloud-data/data";
                  }
                ];
              };
              volumes = [
                {
                  name = "html";
                  persistentVolumeClaim.claimName = "nextcloud-html";
                }
                {
                  name = "data";
                  nfs = {
                    server = (import ../lib/constants.nix).nasServer;
                    path = "/mnt/storage/Operations/nextcloud-data/data";
                  };
                }
                {
                  name = "seed";
                  secret.secretName = "nextcloud-config";
                }
              ];
            };
          };
        };
      };

      services = {
        nextcloud-redis.spec = {
          selector.app = "nextcloud-redis";
          ports.redis.port = 6379;
        };
        nextcloud.spec = {
          selector.app = "nextcloud";
          ports.http.port = 80;
        };
      };

      ingresses.nextcloud = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/target" = (import ../lib/constants.nix).tunnelTarget;
          "traefik.ingress.kubernetes.io/router.middlewares" = "nextcloud-nc-headers@kubernetescrd";
        };
        spec = {
          ingressClassName = "traefik";
          rules =
            let
              ruleFor = host: {
                inherit host;
                http.paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend.service = {
                      name = "nextcloud";
                      port.number = 80;
                    };
                  }
                ];
              };
            in
            [
              (ruleFor "cloud.starcommand.live")
              # fasttrackaudio alias (was a host nginx serverAlias; now routed
              # via Caddy -> Traefik after the host edge moved off nginx).
              (ruleFor "cloud.fasttrackaudio.com")
            ];
        };
      };
    };

    # Traefik forbids multi-type middleware, so headers-only here. (The
    # .well-known caldav/carddav redirect is handled by Nextcloud itself.)
    yamls = [
      ''
        apiVersion: traefik.io/v1alpha1
        kind: Middleware
        metadata:
          name: nc-headers
          namespace: nextcloud
        spec:
          headers:
            customRequestHeaders:
              X-Forwarded-Proto: https
      ''
    ];
  };
}
