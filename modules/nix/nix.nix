# Nix collection facet
# Collects all nix-related configuration aspects
{ fleet, ... }:
{
  fleet.nix = {
    description = ''
      Nix configuration facet.
      Includes nixpkgs overlays, unfree packages, nix-index, nix-registry, npins, and search tools.
    '';

    includes = [
      fleet.nix._.nixpkgs
      fleet.nix._.unfree-default
      fleet.nix._.nix-index
      fleet.nix._.nix-registry
      fleet.nix._.npins
      fleet.nix._.search
    ];
  };
}
