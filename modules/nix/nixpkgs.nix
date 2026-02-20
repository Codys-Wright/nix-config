# Nixpkgs stable and unstable configuration
# Provides overlays for accessing pkgs.stable and pkgs.unstable
{
  inputs,
  FTS,
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

    # Add unstable packages as pkgs.unstable
    # Note: inputs.nixpkgs is already nixpkgs-unstable
    (final: prev: {
      unstable = import inputs.nixpkgs {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];
in
{
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
  flake-file.inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  FTS.nix._.nixpkgs = {
    description = "Nixpkgs stable and unstable overlays (pkgs.stable, pkgs.unstable)";
    nixos.nixpkgs = { inherit overlays; };
    darwin.nixpkgs = { inherit overlays; };
    homeManager.nixpkgs = { inherit overlays; };
  };
}
