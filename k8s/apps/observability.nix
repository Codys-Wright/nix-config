# Observability — kube-prometheus-stack (Prometheus + Grafana + Alertmanager
# + node-exporter + kube-state-metrics). Replaces the host shb monitoring.
# Grafana SSO via Authelia generic_oauth. Host bridge:
# <FTS.cluster/observability-bridge> (OIDC client + secrets).
#
# Prometheus auto-scrapes cluster targets + the node-exporter DaemonSet
# (which runs on starcommand, giving host node metrics). The few host-only
# exporters (nginx/smartctl/authelia) are not migrated — add them via
# additionalScrapeConfigs later if wanted.
{ charts, ... }:
{
  applications.observability = {
    namespace = "observability";
    createNamespace = true;

    helm.releases.kube-prometheus-stack = {
      chart = charts.prometheus-community.kube-prometheus-stack;
      # CRDs are huge; server-side apply.
      transformer = map (
        m:
        if m.kind == "CustomResourceDefinition" then
          (
            m
            // {
              metadata = (m.metadata or { }) // {
                annotations = ((m.metadata or { }).annotations or { }) // {
                  "argocd.argoproj.io/sync-options" = "ServerSideApply=true";
                };
              };
            }
          )
        else
          m
      );
      values = {
        # single always-on node — pin everything to starcommand
        prometheus.prometheusSpec = {
          retention = "30d";
          nodeSelector."kubernetes.io/hostname" = "starcommand";
          # let prometheus pick up ServiceMonitors from any namespace
          serviceMonitorSelectorNilUsesHelmValues = false;
          podMonitorSelectorNilUsesHelmValues = false;
          storageSpec.volumeClaimTemplate.spec = {
            storageClassName = "db-local";
            accessModes = [ "ReadWriteOnce" ];
            resources.requests.storage = "20Gi";
          };
        };

        alertmanager.alertmanagerSpec.nodeSelector."kubernetes.io/hostname" = "starcommand";
        prometheusOperator.nodeSelector."kubernetes.io/hostname" = "starcommand";

        grafana = {
          nodeSelector."kubernetes.io/hostname" = "starcommand";
          admin = {
            existingSecret = "grafana-secrets";
            userKey = "admin-user";
            passwordKey = "admin-password";
          };
          # loads admin-user/password + GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET
          envFromSecret = "grafana-secrets";
          persistence = {
            enabled = true;
            storageClassName = "db-local";
            size = "5Gi";
          };
          "grafana.ini" = {
            server.root_url = "https://grafana.starcommand.live";
            "auth.generic_oauth" = {
              enabled = true;
              name = "Authelia";
              client_id = "grafana";
              # client_secret comes from GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET (envFromSecret)
              scopes = "openid email profile groups";
              auth_url = "https://auth.starcommand.live/api/oidc/authorization";
              token_url = "https://auth.starcommand.live/api/oidc/token";
              api_url = "https://auth.starcommand.live/api/oidc/userinfo";
              use_pkce = true;
              auto_login = false;
              role_attribute_path = "contains(groups[*], 'grafana_admin') && 'Admin' || contains(groups[*], 'grafana_user') && 'Editor' || 'Viewer'";
            };
          };
          ingress = {
            enabled = true;
            ingressClassName = "traefik";
            annotations."external-dns.alpha.kubernetes.io/target" = (import ../lib/constants.nix).tunnelTarget;
            hosts = [ "grafana.starcommand.live" ];
            path = "/";
          };
        };
      };
    };

    # grafana-secrets (keys admin-user, admin-password,
    # GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET) is rendered host-side by
    # <FTS.cluster/observability-bridge>.
  };
}
