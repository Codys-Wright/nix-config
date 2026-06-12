# Argo CD — installed once by hand (just gitops-bootstrap), self-managed
# through this application afterwards.
{ charts, ... }:
{
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;
    helm.releases.argocd = {
      chart = charts.argoproj.argo-cd;
      values = {
        configs.params."server.insecure" = "true";

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
        repoServer.replicas = 1;
        server.replicas = 1;
      };
    };
  };
}
