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
    ../apps/open-webui.nix
    ../apps/storage.nix
    ../apps/whoami.nix
  ];

  nixidy.target = {
    repository = "https://codeberg.org/codywright/nix-fleet.git";
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
