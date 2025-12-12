# Flake inputs for disk management modules
{
  lib,
  ...
}:
{
  flake-file.inputs.disko.url = lib.mkDefault "github:nix-community/disko";
  flake-file.inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
}

