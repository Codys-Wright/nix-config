# nixidy — Nix-rendered Kubernetes manifests for the fleet cluster (GitOps).
#
# Workflow (docs/cluster-design.md, phase 2):
#   edit k8s/**.nix  ->  just gitops-push  ->  Argo CD syncs gitops/prod
#
# The k8s/ tree is NOT under modules/ on purpose: import-tree must not load
# nixidy modules as flake-parts modules.
{ inputs, lib, ... }:
{
  flake-file.inputs.nixidy.url = "github:arnarg/nixidy/latest";
  flake-file.inputs.nixhelm = {
    url = "github:farcaller/nixhelm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.nixidyEnvs.x86_64-linux = inputs.nixidy.lib.mkEnvs {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    charts = inputs.nixhelm.chartsDerivations.x86_64-linux;
    envs.prod.modules = [ ../../k8s/env/prod.nix ];
  };

  perSystem =
    { system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.nixidy = inputs.nixidy.packages.${system}.default;
    };
}
