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
        # The NodePort service never gets an EXTERNAL-IP, so Traefik can't
        # publish a LoadBalancer address back to Ingress .status. Argo then
        # marks every Ingress (and its app) "Progressing" forever. Disable the
        # chart's default publishedService (which points at the IP-less
        # NodePort) and pin the host IP so Traefik writes it into each Ingress
        # status -> Healthy.
        providers.kubernetesIngress = {
          publishedService.enabled = false;
          ingressEndpoint.ip = "10.10.10.1";
        };
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
    # (Traefik CRDs — not in nixidy's typed schema, so raw yaml.)
    yamls = [
      # Authelia forward-auth (4.38+ endpoint). Apps opt in via annotation:
      #   traefik.ingress.kubernetes.io/router.middlewares: traefik-authelia@kubernetescrd
      ''
        apiVersion: traefik.io/v1alpha1
        kind: Middleware
        metadata:
          name: authelia
          namespace: traefik
        spec:
          forwardAuth:
            address: https://auth.starcommand.live/api/authz/forward-auth
            trustForwardHeader: true
            authResponseHeaders:
              - Remote-User
              - Remote-Groups
              - Remote-Email
              - Remote-Name
      ''
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
