# Nix collection facet
# Collects all nix-related configuration aspects
{FTS, ...}: {
  FTS.nix = {
    description = ''
      Nix configuration facet.
      Includes nixpkgs overlays, unfree packages, nix-index, nix-registry, npins, and search tools.
    '';

    includes = [
      FTS.nix._.nixpkgs
      FTS.nix._.unfree-default
      FTS.nix._.nix-index
      FTS.nix._.nix-registry
      FTS.nix._.npins
      FTS.nix._.search
    ];
  };
}
