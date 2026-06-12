# Deluge (deferred from wave 1) — behind a gluetun ProtonVPN sidecar so all
# torrent traffic egresses through the VPN (kill-switch: if the tunnel drops,
# gluetun's firewall blocks everything). deluge shares gluetun's network
# namespace. Host bridge: <FTS.cluster/deluge-bridge> (OpenVPN creds + rules).
{ ... }:
{
  applications.deluge = {
    namespace = "selfhost";

    resources = {
      persistentVolumeClaims."deluge-state".spec = {
        accessModes = [ "ReadWriteOnce" ];
        storageClassName = "db-local";
        resources.requests.storage = "2Gi";
      };

      deployments.deluge.spec = {
        replicas = 1;
        strategy.type = "Recreate";
        selector.matchLabels.app = "deluge";
        template = {
          metadata.labels.app = "deluge";
          spec = {
            enableServiceLinks = false;
            containers = {
              gluetun = {
                image = "qmcgaw/gluetun:v3";
                securityContext = {
                  capabilities.add = [ "NET_ADMIN" ];
                };
                env = [
                  {
                    name = "VPN_SERVICE_PROVIDER";
                    value = "protonvpn";
                  }
                  {
                    name = "VPN_TYPE";
                    value = "openvpn";
                  }
                  {
                    name = "OPENVPN_USER";
                    valueFrom.secretKeyRef = {
                      name = "gluetun-creds";
                      key = "OPENVPN_USER";
                    };
                  }
                  {
                    name = "OPENVPN_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "gluetun-creds";
                      key = "OPENVPN_PASSWORD";
                    };
                  }
                  # Allow the deluge web UI + LAN to reach the pod despite the
                  # VPN firewall (cluster pod/service CIDRs + LAN).
                  {
                    name = "FIREWALL_OUTBOUND_SUBNETS";
                    value = "10.42.0.0/16,10.43.0.0/16,10.10.10.0/24,192.168.0.0/16";
                  }
                  {
                    name = "TZ";
                    value = "America/Chicago";
                  }
                ];
                volumeMounts = [
                  {
                    name = "tun";
                    mountPath = "/dev/net/tun";
                  }
                ];
              };
              deluge = {
                image = "lscr.io/linuxserver/deluge:latest";
                env = [
                  {
                    name = "PUID";
                    value = "0";
                  }
                  {
                    name = "PGID";
                    value = "0";
                  }
                  {
                    name = "TZ";
                    value = "America/Chicago";
                  }
                ];
                ports.web.containerPort = 8112;
                volumeMounts = [
                  {
                    name = "state";
                    mountPath = "/config";
                  }
                  {
                    name = "downloads";
                    mountPath = "/mnt/storage/Operations/torrents";
                  }
                ];
              };
            };
            volumes = [
              {
                name = "state";
                persistentVolumeClaim.claimName = "deluge-state";
              }
              {
                name = "downloads";
                nfs = {
                  server = "10.10.10.1";
                  path = "/mnt/storage/Operations/torrents";
                };
              }
              {
                name = "tun";
                hostPath = {
                  path = "/dev/net/tun";
                  type = "CharDevice";
                };
              }
            ];
          };
        };
      };

      services.deluge.spec = {
        selector.app = "deluge";
        ports.web.port = 80;
        ports.web.targetPort = 8112;
      };

      ingresses.deluge = {
        metadata.annotations = {
          "external-dns.alpha.kubernetes.io/target" = "803700ac-6ca2-4041-94c7-3d1c9ef05e52.cfargotunnel.com";
          "traefik.ingress.kubernetes.io/router.middlewares" = "traefik-authelia@kubernetescrd";
        };
        spec = {
          ingressClassName = "traefik";
          rules = [
            {
              host = "torrents.starcommand.live";
              http.paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend.service = {
                    name = "deluge";
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
