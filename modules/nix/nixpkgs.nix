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

  # Nixpkgs aspect - provides stable and unstable overlays
  FTS.nix._.nixpkgs = {
    description = "Nixpkgs stable and unstable overlays (pkgs.stable, pkgs.unstable)";
    # This aspect configures flake-level overlays, so it applies to all classes
    # The overlays are configured at the flake module level
  };

  # Overlays for accessing stable and unstable nixpkgs
  flake.modules.nixos.nixpkgs = { inherit overlays; };
  flake.modules.darwin.nixpkgs = { inherit overlays; };
  flake.modules.homeManager.nixpkgs = { inherit overlays; };
}
