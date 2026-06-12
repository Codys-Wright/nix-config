# Invoice Ninja (last host service) — Laravel/Octane invoicing platform.
# Unlike the Postgres apps it needs MySQL, so it carries its own MariaDB
# Deployment (db-local PVC, pinned to starcommand) rather than using pg-main.
#
#   web        invoiceninja/invoiceninja-octane:5  (serves on :8000)
#   db         mariadb:11                           (db-local, internal)
#   scheduler  CronJob `php artisan schedule:run`   (every minute, was a
#              host systemd timer that did `podman exec ... schedule:run`)
#
# Storage (uploaded invoices/PDFs) lives on the NAS over NFS so it survives.
# No Authelia forward-auth: Invoice Ninja owns its login + public client
# portal + payment webhooks.
#
# Secrets (APP_KEY, DB_PASSWORD1) come from the host bridge as the
# `invoiceninja-secrets` Secret. Host bridge: <FTS.cluster/invoiceninja-bridge>.
{ ... }:
let
  webImage = "invoiceninja/invoiceninja-octane:5";
  dbImage = "mariadb:11";
  port = 8000;

  # APP_KEY + DB_PASSWORD1 from the bridge-rendered Secret.
  secretEnv = key: {
    name = key;
    valueFrom.secretKeyRef = {
      name = "invoiceninja-secrets";
      inherit key;
    };
  };

  appEnv = [
    (secretEnv "APP_KEY")
    (secretEnv "DB_PASSWORD1")
    # init.sh (set -u) requires these to seed the first admin on an empty DB.
    # Reuse the strong db_password as the seed login password — change it in
    # the app after first login.
    {
      name = "IN_USER_EMAIL";
      value = "acodywright@gmail.com";
    }
    (secretEnv "DB_PASSWORD1" // { name = "IN_USER_PASSWORD"; })
    {
      name = "APP_ENV";
      value = "production";
    }
    {
      name = "APP_DEBUG";
      value = "false";
    }
    {
      name = "APP_URL";
      value = "https://invoice.starcommand.live";
    }
    {
      name = "APP_FORCE_HTTPS";
      value = "true";
    }
    {
      name = "REQUIRE_HTTPS";
      value = "true";
    }
    {
      name = "TRUSTED_PROXIES";
      value = "*";
    }
    {
      name = "MAIL_MAILER";
      value = "log";
    }
    {
      name = "QUEUE_CONNECTION";
      value = "database";
    }
    {
      name = "DB_TYPE1";
      value = "mysql";
    }
    {
      name = "DB_HOST1";
      value = "invoiceninja-db";
    }
    {
      name = "DB_PORT";
      value = "3306";
    }
    {
      name = "DB_DATABASE1";
      value = "invoiceninja";
    }
    {
      name = "DB_USERNAME1";
      value = "invoiceninja";
    }
  ];

  # The octane image lives at /app (WORKDIR), so persistent state is
  # /app/storage (uploads, logs, sessions, compiled views).
  storageMount = {
    name = "storage";
    mountPath = "/app/storage";
  };
  storageVolume = {
    name = "storage";
    persistentVolumeClaim.claimName = "invoiceninja-storage";
  };
in
{
  applications.invoiceninja = {
    namespace = "selfhost";
    createNamespace = false; # shared selfhost ns owned by namespaces.nix

    resources = {
      persistentVolumeClaims = {
        # Local (db-local), not NFS: the NAS export uses all_squash, which
        # collides with the octane container's ninja(999) user when it writes
        # framework/cache. Pinned to starcommand like the DB.
        "invoiceninja-storage".spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "db-local";
          resources.requests.storage = "5Gi";
        };
        "invoiceninja-db".spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "db-local";
          resources.requests.storage = "3Gi";
        };
      };

      deployments = {
        invoiceninja-db.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "invoiceninja-db";
          template = {
            metadata.labels.app = "invoiceninja-db";
            spec = {
              enableServiceLinks = false;
              nodeSelector."kubernetes.io/hostname" = "starcommand";
              containers.mariadb = {
                image = dbImage;
                ports.mysql.containerPort = 3306;
                env = [
                  {
                    name = "MARIADB_DATABASE";
                    value = "invoiceninja";
                  }
                  {
                    name = "MARIADB_USER";
                    value = "invoiceninja";
                  }
                  (secretEnv "DB_PASSWORD1" // { name = "MARIADB_PASSWORD"; })
                  (secretEnv "DB_PASSWORD1" // { name = "MARIADB_ROOT_PASSWORD"; })
                ];
                volumeMounts = [
                  {
                    name = "db";
                    mountPath = "/var/lib/mysql";
                  }
                ];
              };
              volumes = [
                {
                  name = "db";
                  persistentVolumeClaim.claimName = "invoiceninja-db";
                }
              ];
            };
          };
        };

        invoiceninja.spec = {
          replicas = 1;
          strategy.type = "Recreate";
          selector.matchLabels.app = "invoiceninja";
          template = {
            metadata.labels.app = "invoiceninja";
            spec = {
              enableServiceLinks = false;
              nodeSelector."kubernetes.io/hostname" = "starcommand";
              # The empty PVC would shadow the image's /app/storage skeleton
              # (framework/cache, sessions, views). Seed it once, then hand
              # ownership to ninja(999).
              initContainers.seed-storage = {
                image = webImage;
                command = [
                  "sh"
                  "-c"
                  ''
                    if [ ! -d /seed/framework ]; then
                      cp -a /app/storage/. /seed/
                      echo "seeded storage skeleton"
                    fi
                    # The image omits framework/cache/data, so Laravel's file
                    # cache flush returns false ("Failed to clear cache") on
                    # boot. Ensure all the writable runtime dirs exist.
                    mkdir -p \
                      /seed/framework/cache/data \
                      /seed/framework/sessions \
                      /seed/framework/views \
                      /seed/app/public \
                      /seed/logs
                    chown -R 999:999 /seed
                  ''
                ];
                securityContext.runAsUser = 0;
                volumeMounts = [
                  {
                    name = "storage";
                    mountPath = "/seed";
                  }
                ];
              };
              containers.invoiceninja = {
                image = webImage;
                ports.http.containerPort = port;
                env = appEnv;
                volumeMounts = [ storageMount ];
              };
              volumes = [ storageVolume ];
            };
          };
        };
      };

      services = {
        invoiceninja-db.spec = {
          selector.app = "invoiceninja-db";
          ports.mysql.port = 3306;
        };
        invoiceninja.spec = {
          selector.app = "invoiceninja";
          ports.http = {
            port = 80;
            targetPort = port;
          };
        };
      };

      cronJobs.invoiceninja-scheduler.spec = {
        schedule = "* * * * *";
        concurrencyPolicy = "Forbid";
        jobTemplate.spec.template.spec = {
          enableServiceLinks = false;
          nodeSelector."kubernetes.io/hostname" = "starcommand";
          restartPolicy = "Never";
          containers.scheduler = {
            image = webImage;
            command = [
              "php"
              "artisan"
              "schedule:run"
            ];
            env = appEnv;
            volumeMounts = [ storageMount ];
          };
          volumes = [ storageVolume ];
        };
      };

      ingresses.invoiceninja = {
        metadata.annotations."external-dns.alpha.kubernetes.io/target" =
          "803700ac-6ca2-4041-94c7-3d1c9ef05e52.cfargotunnel.com";
        spec = {
          ingressClassName = "traefik";
          rules =
            let
              # external-dns only owns starcommand.live; the fasttrackaudio
              # alias reaches Traefik via the host nginx vhost (bridge),
              # so it just needs a matching Traefik routing rule here.
              ruleFor = host: {
                inherit host;
                http.paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend.service = {
                      name = "invoiceninja";
                      port.number = 80;
                    };
                  }
                ];
              };
            in
            [
              (ruleFor "invoice.starcommand.live")
              (ruleFor "invoice.fasttrackaudio.com")
            ];
        };
      };
    };
  };
}
