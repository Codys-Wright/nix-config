# whoami — pipeline smoke test: proves Argo CD sync, scheduling, and
# csi-driver-nfs provisioning (the PVC) end to end. Delete once real
# apps are migrated.
{ ... }:
{
  applications.whoami = {
    namespace = "whoami";
    createNamespace = true;

    resources = {
      persistentVolumeClaims.whoami-data.spec = {
        accessModes = [ "ReadWriteMany" ];
        storageClassName = "nas-nfs";
        resources.requests.storage = "100Mi";
      };

      deployments.whoami.spec = {
        replicas = 1;
        selector.matchLabels.app = "whoami";
        template = {
          metadata.labels.app = "whoami";
          spec = {
            containers.whoami = {
              image = "traefik/whoami:v1.10.3";
              ports.http.containerPort = 80;
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
                persistentVolumeClaim.claimName = "whoami-data";
              }
            ];
          };
        };
      };

      services.whoami.spec = {
        selector.app = "whoami";
        ports.http.port = 80;
      };
    };
  };
}
