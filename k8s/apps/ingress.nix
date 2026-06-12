# Cluster ingress foundation: Traefik + external-dns.
#
# Path for every migrated app:
#   CF DNS (external-dns creates CNAME -> tunnel) -> cloudflared on
#   starcommand (defaultService fall-through) -> Traefik NodePort 30880
#   -> Ingress -> Service.
#
# Migrating an app needs ONE nixidy file with an Ingress — no host nginx
# vhost, no tunnel list entry, no starcommand deploy.
{ charts, lib, ... }:
{
  applications.traefik = {
    namespace = "traefik";
    createNamespace = true;
    helm.releases.traefik = {
      chart = charts.traefik.traefik;
      values = {
        # TLS terminates at the Cloudflare edge; the tunnel reaches Traefik
        # over plain http on the NodePort.
        service.type = "NodePort";
        ports.web.nodePort = 30880;
        ports.websecure.expose.default = false;
        # Visitors only ever arrive via https (CF edge + tunnel) — make sure
        # apps see that, since the original scheme does not survive the
        # tunnel in X-Forwarded-Proto.
        additionalArguments = [
          "--entryPoints.web.forwardedHeaders.insecure=true"
        ];
        # Run on the always-on node next to the tunnel.
        nodeSelector."kubernetes.io/hostname" = "starcommand";
      };
    };
    # Set X-Forwarded-Proto https for everything entering via the tunnel.
    # (Traefik CRD — not in nixidy's typed schema, so raw yaml.)
    yamls = [
      ''
        apiVersion: traefik.io/v1alpha1
        kind: Middleware
        metadata:
          name: https-headers
          namespace: traefik
        spec:
          headers:
            customRequestHeaders:
              X-Forwarded-Proto: https
      ''
    ];
  };

  applications.external-dns = {
    namespace = "external-dns";
    createNamespace = true;
    helm.releases.external-dns = {
      chart = charts.kubernetes-sigs.external-dns;
      values = {
        provider.name = "cloudflare";
        env = [
          {
            name = "CF_API_TOKEN";
            valueFrom.secretKeyRef = {
              name = "external-dns-cloudflare";
              key = "api-token";
            };
          }
        ];
        domainFilters = [ "starcommand.live" ];
        sources = [ "ingress" ];
        # Never delete records it didn't create; never touch existing ones.
        policy = "upsert-only";
        txtOwnerId = "fleet-k3s";
        extraArgs = [ "--cloudflare-proxied" ];
        nodeSelector."kubernetes.io/hostname" = "starcommand";
      };
    };
  };
}
