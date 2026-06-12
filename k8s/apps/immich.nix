# Immich (wave 3b). Dedicated CNPG cluster on the VectorChord image (pg-main's
# stock image lacks the vector extensions immich needs). Server + ML + redis.
# Media mounts at the SAME host path so the DB's absolute paths stay valid.
# Host bridge: <FTS.cluster/immich-bridge> (Authelia OIDC client).
{ ... }:
{
  applications.immich = {
    namespace = "immich";
    createNamespace = true;

    resources = {
      persistentVolumeClaims = {
        # ML model cache — local, rebuildable
        "immich-ml-cache".spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "db-local";
          resources.requests.storage = "10Gi";
        };
      };

      deployments = {
        redis.spec = {
          replicas = 1;
          selector.matchLabels.app = "immich-redis";
          template = {
            metadata.labels.app = "immich-redis";
            spec = {
              enableServiceLinks = false;
              containers.redis = {
                image = "valkey/valkey:8";
                ports.redis.containerPort = 6379;
              };
            };
          };
        };

        immich-server.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "immich-server";
          template = {
            metadata.labels.app = "immich-server";
            spec = {
              enableServiceLinks = false;
              containers.immich-server = {
                image = "ghcr.io/immich-app/immich-server:v2.7.5";
                ports.http.containerPort = 2283;
                env = [
                  {
                    name = "DB_HOSTNAME";
                    value = "immich-postgresql-rw";
                  }
                  {
                    name = "DB_PORT";
                    value = "5432";
                  }
                  {
                    name = "DB_DATABASE_NAME";
                    value = "immich";
                  }
                  {
                    name = "DB_USERNAME";
                    valueFrom.secretKeyRef = {
                      name = "immich-postgresql-app";
                      key = "username";
                    };
                  }
                  {
                    name = "DB_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "immich-postgresql-app";
                      key = "password";
                    };
                  }
                  {
                    name = "DB_VECTOR_EXTENSION";
                    value = "vectorchord";
                  }
                  {
                    name = "REDIS_HOSTNAME";
                    value = "immich-redis";
                  }
                  {
                    name = "REDIS_PORT";
                    value = "6379";
                  }
                  {
                    name = "IMMICH_MACHINE_LEARNING_URL";
                    value = "http://immich-ml:3003";
                  }
                  {
                    name = "IMMICH_MEDIA_LOCATION";
                    value = "/mnt/storage/Operations/photos";
                  }
                ];
                volumeMounts = [
                  {
                    name = "photos";
                    mountPath = "/mnt/storage/Operations/photos";
                  }
                ];
              };
              volumes = [
                {
                  name = "photos";
                  nfs = {
                    server = "10.10.10.1";
                    path = "/mnt/storage/Operations/photos";
                  };
                }
              ];
            };
          };
        };

        immich-ml.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "immich-ml";
          template = {
            metadata.labels.app = "immich-ml";
            spec = {
              enableServiceLinks = false;
              containers.immich-ml = {
                image = "ghcr.io/immich-app/immich-machine-learning:v2.7.5";
                ports.ml.containerPort = 3003;
                volumeMounts = [
                  {
                    name = "cache";
                    mountPath = "/cache";
                  }
                ];
              };
              volumes = [
                {
                  name = "cache";
                  persistentVolumeClaim.claimName = "immich-ml-cache";
                }
              ];
            };
          };
        };
      };

      services = {
        immich-redis.spec = {
          selector.app = "immich-redis";
          ports.redis.port = 6379;
        };
        immich-ml.spec = {
          selector.app = "immich-ml";
          ports.ml.port = 3003;
        };
        immich-server.spec = {
          selector.app = "immich-server";
          ports.http.port = 80;
          ports.http.targetPort = 2283;
        };
      };

      ingresses.immich = {
        metadata.annotations."external-dns.alpha.kubernetes.io/target" =
          "803700ac-6ca2-4041-94c7-3d1c9ef05e52.cfargotunnel.com";
        spec = {
          ingressClassName = "traefik";
          rules = [
            {
              host = "photos.starcommand.live";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "immich-server";
                    port.number = 80;
                  };
                }
              ];
            }
          ];
        };
      };
    };

    # Dedicated CNPG cluster on the VectorChord image.
    yamls = [
      ''
        apiVersion: postgresql.cnpg.io/v1
        kind: Cluster
        metadata:
          name: immich-postgresql
          namespace: immich
          annotations:
            argocd.argoproj.io/sync-options: Prune=false,Delete=false
        spec:
          instances: 1
          imageName: ghcr.io/tensorchord/cloudnative-vectorchord:16-1.1.1
          enableSuperuserAccess: true
          storage:
            storageClass: local-path
            size: 20Gi
          affinity:
            nodeSelector:
              kubernetes.io/hostname: starcommand
          postgresql:
            shared_preload_libraries:
              - vchord.so
          bootstrap:
            initdb:
              database: immich
              owner: immich
              postInitSQL:
                - CREATE EXTENSION IF NOT EXISTS "vchord" CASCADE
                - CREATE EXTENSION IF NOT EXISTS "earthdistance" CASCADE
      ''
    ];
  };
}
