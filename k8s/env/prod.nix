# nixidy environment: prod — the fleet cluster.
#
# Rendered manifests are pushed to the orphan branch gitops/prod of the
# PUBLIC nix-fleet repo (manifests contain no secrets; secret material enters
# the cluster via NixOS-side sops templates on starcommand, never via git).
{ ... }:
{
  nixidy.chartsDir = ../charts;

  imports = [
    ../apps/argocd.nix
    ../apps/ingress.nix
    ../apps/wave1.nix
    ../apps/wave2.nix
    ../apps/databases.nix
    ../apps/wave3a.nix
    ../apps/immich.nix
    ../apps/forgejo.nix
    ../apps/nextcloud.nix
    ../apps/deluge.nix
    ../apps/invoiceninja.nix
    ../apps/auth.nix
    ../apps/observability.nix
    ../apps/open-webui.nix
    ../apps/registry.nix
    ../apps/task.nix
    ../apps/cluster-secrets.nix
    ../apps/namespaces.nix
    ../apps/storage.nix
    ../apps/whoami.nix
  ];

  # Where Argo READS the rendered manifests from. Every generated
  # Application's repoURL is stamped from this, so it must match what the
  # app-of-apps actually watches -- Codys-Wright/starcommand. It still said
  # codeberg.org/codywright/nix-fleet, which predates the move to GitHub:
  # the live cluster had been hand-updated to starcommand, so the first
  # honest `gitops-push` would have repointed EVERY Application at a repo
  # Argo cannot read, taking the whole cluster with it.
  nixidy.target = {
    repository = "git@github.com:Codys-Wright/starcommand.git";
    branch = "gitops/prod";
    rootPath = "./";
  };

  # Everything syncs automatically; prune + selfHeal keep the cluster honest.
  nixidy.defaults.syncPolicy.autoSync = {
    enable = true;
    prune = true;
    selfHeal = true;
  };
}
