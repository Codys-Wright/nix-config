# Forgejo (wave 3b). forgejo-helm v17.1.1, external CNPG (pg-main forgejo db),
# repos on a local-path PVC. SSH exposed on a NodePort (host forwards
# git.starcommand.live:2222 -> here). Host bridge: <FTS.cluster/forgejo-bridge>
# (OIDC client + DB password secret + nginx git vhost + ssh forward).
{ charts, ... }:
{
  applications.forgejo = {
    namespace = "forgejo";
    createNamespace = true;

    helm.releases.forgejo = {
      chart = charts.forgejo-helm.forgejo;
      values = {
        replicaCount = 1;
        strategy.type = "Recreate";

        persistence = {
          enabled = true;
          size = "50Gi";
          storageClass = "local-path";
          accessModes = [ "ReadWriteOnce" ];
        };

        ingress.enabled = false;

        service = {
          http = {
            type = "ClusterIP";
            port = 3000;
          };
          ssh = {
            type = "NodePort";
            port = 22;
            nodePort = 32222;
          };
        };

        gitea.config = {
          server = {
            DOMAIN = "git.starcommand.live";
            SSH_DOMAIN = "git.starcommand.live";
            ROOT_URL = "https://git.starcommand.live/";
            HTTP_PORT = 3000;
            SSH_PORT = 2222; # advertised in clone URLs (host forwards :2222)
            SSH_LISTEN_PORT = 2222;
            START_SSH_SERVER = true;
          };
          database = {
            DB_TYPE = "postgres";
            HOST = "pg-main-rw.databases.svc:5432";
            NAME = "forgejo";
            USER = "forgejo";
            SSL_MODE = "require";
          };
          service.DISABLE_REGISTRATION = true;
        };

        # DB password from the bridge-rendered secret (gitea.* namespace in
        # the chart, injected into app.ini [database] PASSWD at runtime).
        gitea.additionalConfigFromEnvs = [
          {
            name = "FORGEJO__database__PASSWD";
            valueFrom.secretKeyRef = {
              name = "forgejo-db";
              key = "password";
            };
          }
        ];
      };
    };

    # Ingress in front of the chart's http service (named "forgejo-http").
    resources.ingresses.forgejo = {
      metadata.annotations."external-dns.alpha.kubernetes.io/target" =
        "803700ac-6ca2-4041-94c7-3d1c9ef05e52.cfargotunnel.com";
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
                    name = "forgejo-http";
                    port.number = 3000;
                  };
                }
              ];
            };
          in
          [
            (ruleFor "git.starcommand.live")
            # fasttrackstudio.app alias (was a host nginx serverAlias; now via
            # Caddy -> Traefik after the host edge moved off nginx).
            (ruleFor "git.fasttrackstudio.app")
          ];
      };
    };
  };
}
