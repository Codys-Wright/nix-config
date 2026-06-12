# mkSimpleApp — the wave-migration shape: one container, state on nas-nfs,
# optional NFS media mounts, Ingress through the Traefik+external-dns path,
# optional Authelia forward-auth.
#
# Usage:
#   (import ../lib/simple-app.nix) {
#     name = "pinchflat"; host = "youtube.starcommand.live";
#     image = "ghcr.io/kieraneglin/pinchflat:latest"; port = 8945;
#     state = { mountPath = "/config"; size = "5Gi"; };
#     nfsMounts = [ { name = "media"; path = "/mnt/storage/Operations/youtube"; mountPath = "/downloads"; } ];
#     auth = true;  # Authelia forward-auth middleware
#     env = [ { name = "TZ"; value = "America/Chicago"; } ];
#   }
{
  name,
  host,
  image,
  port,
  namespace ? "selfhost",
  state ? null, # { mountPath, size, class ? "nas-nfs" } -> PVC <name>-state
  nfsMounts ? [ ], # [{ name, path, mountPath }] straight NFS from the NAS
  auth ? false, # true = Authelia forward-auth at Traefik
  env ? [ ],
  podSecurityContext ? { },
  tunnelTarget ? "803700ac-6ca2-4041-94c7-3d1c9ef05e52.cfargotunnel.com",
}:
let
  stateVolume =
    if state != null then
      [
        {
          name = "state";
          persistentVolumeClaim.claimName = "${name}-state";
        }
      ]
    else
      [ ];
  stateMount =
    if state != null then
      [
        {
          name = "state";
          mountPath = state.mountPath;
        }
      ]
    else
      [ ];
  mediaVolumes = map (m: {
    inherit (m) name;
    nfs = {
      server = "10.10.10.1";
      path = m.path;
    };
  }) nfsMounts;
  mediaMounts = map (m: {
    inherit (m) name mountPath;
  }) nfsMounts;
in
{
  applications.${name} = {
    inherit namespace;
    createNamespace = false; # shared selfhost ns owned by namespaces.nix

    resources =
      (
        if state != null then
          {
            persistentVolumeClaims."${name}-state".spec = {
              accessModes =
                if (state.class or "nas-nfs") == "nas-nfs" then [ "ReadWriteMany" ] else [ "ReadWriteOnce" ];
              storageClassName = state.class or "nas-nfs";
              resources.requests.storage = state.size;
            };
          }
        else
          { }
      )
      // {
        deployments.${name}.spec = {
          replicas = 1;
          strategy.type = "Recreate"; # single PVC writer
          selector.matchLabels.app = name;
          template = {
            metadata.labels.app = name;
            spec = {
              # k8s injects <SVC>_PORT=tcp://... env vars for every service in
              # the namespace — they collide with app config (bit hledger).
              enableServiceLinks = false;
              securityContext = podSecurityContext;
              containers.${name} = {
                inherit image env;
                ports.http.containerPort = port;
                volumeMounts = stateMount ++ mediaMounts;
              };
              volumes = stateVolume ++ mediaVolumes;
            };
          };
        };

        services.${name}.spec = {
          selector.app = name;
          ports.http.port = 80;
          ports.http.targetPort = port;
        };

        ingresses.${name} = {
          metadata.annotations = {
            "external-dns.alpha.kubernetes.io/target" = tunnelTarget;
          }
          // (
            if auth then
              {
                "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-authelia@kubernetescrd";
              }
            else
              { }
          );
          spec = {
            ingressClassName = "traefik";
            rules = [
              {
                inherit host;
                http.paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend.service = {
                      name = name;
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
