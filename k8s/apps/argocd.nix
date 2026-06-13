# Argo CD — installed once by hand (just gitops-bootstrap), self-managed
# through this application afterwards.
#
# sops CMP: a repo-server sidecar (argocd-cmp-server) that decrypts
# sops-encrypted manifests at sync time. It auto-discovers any app whose source
# dir contains a `*.enc.yaml` (today only the cluster-secrets app, via nixidy
# extraRawYamls) and runs `sops -d` on each. The age private key is mounted from
# the `sops-age` Secret (delivered by the host <FTS.cluster/age-bridge>, the one
# bootstrap secret). sops has age decryption built in, so no separate `age`
# binary is needed — only the sops binary, copied in by an initContainer.
{ charts, ... }:
let
  # Match the chart's bundled Argo CD (appVersion) so the cmp-server binary in
  # the sidecar matches the repo-server.
  argocdImage = "quay.io/argoproj/argocd:v3.4.3";
  sopsVersion = "3.9.4";
in
{
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;
    helm.releases.argocd = {
      chart = charts.argoproj.argo-cd;
      values = {
        configs.params."server.insecure" = "true";

        # ── sops CMP plugin ──────────────────────────────────────────────
        # Discovers app dirs containing *.enc.yaml; decrypts each with sops.
        configs.cmp = {
          create = true;
          plugins.sops = {
            version = "v1.0";
            discover.find.glob = "**/*.enc.yaml";
            generate.command = [
              "sh"
              "-c"
              "for f in $(find . -name '*.enc.yaml' | sort); do sops -d \"$f\"; echo '---'; done"
            ];
          };
        };

        repoServer = {
          replicas = 1;
          # Pull the sops binary into a shared volume (sops bundles age decrypt).
          initContainers = [
            {
              name = "install-sops";
              image = "alpine:3.20";
              command = [
                "sh"
                "-c"
                "wget -qO /custom-tools/sops https://github.com/getsops/sops/releases/download/v${sopsVersion}/sops-v${sopsVersion}.linux.amd64 && chmod +x /custom-tools/sops"
              ];
              volumeMounts = [
                {
                  name = "custom-tools";
                  mountPath = "/custom-tools";
                }
              ];
            }
          ];
          # The CMP sidecar: argocd-cmp-server serving the sops plugin.
          extraContainers = [
            {
              name = "cmp-sops";
              image = argocdImage;
              command = [ "/var/run/argocd/argocd-cmp-server" ];
              securityContext = {
                runAsNonRoot = true;
                runAsUser = 999;
              };
              env = [
                {
                  name = "SOPS_AGE_KEY_FILE";
                  value = "/home/argocd/.config/sops/age/keys.txt";
                }
              ];
              volumeMounts = [
                {
                  name = "var-files";
                  mountPath = "/var/run/argocd";
                }
                {
                  name = "plugins";
                  mountPath = "/home/argocd/cmp-server/plugins";
                }
                {
                  name = "argocd-cmp-cm";
                  mountPath = "/home/argocd/cmp-server/config/plugin.yaml";
                  subPath = "sops.yaml";
                }
                {
                  name = "custom-tools";
                  mountPath = "/usr/local/bin/sops";
                  subPath = "sops";
                }
                {
                  name = "sops-age";
                  mountPath = "/home/argocd/.config/sops/age";
                }
              ];
            }
          ];
          volumes = [
            {
              name = "custom-tools";
              emptyDir = { };
            }
            {
              name = "argocd-cmp-cm";
              configMap.name = "argocd-cmp-cm";
            }
            {
              name = "sops-age";
              secret.secretName = "sops-age";
            }
          ];
        };

        # SSO via Authelia. The client secret arrives as k8s Secret
        # argocd-oidc (starcommand <FTS.cluster/argocd-bridge>); the
        # part-of=argocd label lets argocd-cm dereference it.
        configs.cm = {
          url = "https://argocd.starcommand.live";
          "oidc.config" = ''
            name: Authelia
            issuer: https://auth.starcommand.live
            clientID: argocd
            clientSecret: $argocd-oidc:client-secret
            requestedScopes:
              - openid
              - email
              - profile
              - groups
          '';
        };
        configs.rbac = {
          "policy.default" = "role:readonly";
          "policy.csv" = ''
            g, lldap_admin, role:admin
          '';
          scopes = "[groups]";
        };
        # Exposed at https://argocd.starcommand.live through the cloudflare
        # tunnel on starcommand (tunnelPortIngress -> this NodePort).
        server.service = {
          type = "NodePort";
          nodePortHttp = 30080;
        };
        # Single always-on node today; HA components are pointless until
        # more permanent nodes exist.
        controller.replicas = 1;
        server.replicas = 1;
      };
    };
  };
}
