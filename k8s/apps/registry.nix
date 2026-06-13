# In-cluster OCI registry — the deployment artifact store for the cluster's own
# images (Task et al.). Plain-HTTP, LAN-only NodePort (10.10.10.1:30050); CI on
# THEBATTLESHIP pushes over the LAN and k3s pulls from the same endpoint.
#
# The workload lives here (nixidy/Argo). The HOST side keeps only what must be
# NixOS: containerd's registries.yaml (so the node trusts the insecure endpoint)
# and /etc/hosts (registry.starcommand.live -> 10.10.10.1) — see
# starcommand <FTS.cluster/registry-bridge>.
{ ... }:
{
  applications.registry = {
    namespace = "registry";
    createNamespace = true;

    resources = {
      persistentVolumeClaims.registry-data.spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "nas-nfs";
        resources.requests.storage = "50Gi";
      };

      deployments.registry.spec = {
        replicas = 1;
        strategy.type = "Recreate";
        selector.matchLabels.app = "registry";
        template = {
          metadata.labels.app = "registry";
          spec = {
            enableServiceLinks = false;
            containers.registry = {
              image = "registry:2.8.3";
              ports.http.containerPort = 5000;
              env = [
                {
                  name = "REGISTRY_HTTP_ADDR";
                  value = ":5000";
                }
                # Allow blob deletes so a future GC can reclaim space from
                # overwritten dev/latest tags.
                {
                  name = "REGISTRY_STORAGE_DELETE_ENABLED";
                  value = "true";
                }
              ];
              volumeMounts = [
                {
                  name = "data";
                  mountPath = "/var/lib/registry";
                }
              ];
              readinessProbe = {
                httpGet = {
                  path = "/v2/";
                  port = 5000;
                };
                initialDelaySeconds = 5;
              };
              livenessProbe = {
                httpGet = {
                  path = "/v2/";
                  port = 5000;
                };
                initialDelaySeconds = 10;
              };
            };
            volumes = [
              {
                name = "data";
                persistentVolumeClaim.claimName = "registry-data";
              }
            ];
          };
        };
      };

      services.registry.spec = {
        type = "NodePort";
        selector.app = "registry";
        ports.registry = {
          port = 5000;
          targetPort = 5000;
          nodePort = 30050;
        };
      };
    };
  };
}
