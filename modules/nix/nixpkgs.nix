# Nixpkgs stable and unstable configuration
# Provides overlays for accessing pkgs.stable and pkgs.unstable
{
  inputs,
  fleet,
  ...
}:
let
  # Shared overlay definitions — identical for nixos, darwin, and homeManager
  overlays = [
    # Add stable packages as pkgs.stable
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
    # pkgs is already nixpkgs-unstable, no overlay needed for pkgs.unstable
  ];
in
{
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
  # nixpkgs-unstable removed — inputs.nixpkgs is already nixpkgs-unstable

  fleet.nix._.nixpkgs = {
    description = "Nixpkgs stable overlay (pkgs.stable) — pkgs is already unstable";
    nixos.nixpkgs = { inherit overlays; };
    darwin.nixpkgs = { inherit overlays; };
    homeManager.nixpkgs = { inherit overlays; };
  };
}
