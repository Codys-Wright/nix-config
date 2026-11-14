# Panix — a phase-oriented Nix deploy orchestrator (github:mihakrumpestar/panix),
# adopted BESIDE deploy-rs, not instead of it. See docs/panix.md for what it
# does on a target, what its rollback does and does not cover, and the
# migration plan. `just panix-plan|panix-deploy|panix-rollback` drive it with
# the generated panix.yml (modules/flake/panix-manifest.nix).
#
# Pinned to a release tag. Built from source: Panix's own Cachix cache
# (mihakrumpestar.cachix.org) is deliberately NOT added to the fleet
# substituters — a Go build takes seconds, and trusting that key would let
# its holder serve any store path to every fleet host (docs/panix.md).
#
# AGPL-3.0: the fleet only runs the binary as a tool; nothing here vendors,
# modifies or links Panix's code.
{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.panix.url = lib.mkDefault "github:mihakrumpestar/panix/v0.12.0";
  flake-file.inputs.panix.inputs.nixpkgs.follows = "nixpkgs";

  # The fleet dev shell (modules/flake/devShells.nix) picks this up too.
  perSystem =
    { inputs', ... }:
    {
      packages.panix = inputs'.panix.packages.default;
    };

  fleet.deployment._.panix = {
    description = "Panix deploy orchestrator CLI (+ GNU rsync >= 3.2.3, which it needs on the control host)";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.panix.packages.${pkgs.stdenv.hostPlatform.system}.default
          # macOS ships rsync 2.6.9 / openrsync, which lack --mkpath.
          pkgs.rsync
        ];
      };
  };
}
