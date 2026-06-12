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
        # No ingress yet — reach it with:
        #   kubectl -n argocd port-forward svc/argocd-server 8080:80
        configs.params."server.insecure" = "true";
        # Single always-on node today; HA components are pointless until
        # more permanent nodes exist.
        controller.replicas = 1;
        repoServer.replicas = 1;
        server.replicas = 1;
      };
    };
  };
}
