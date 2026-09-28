{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.hm-cli = {
    description = "Adds the home-manager CLI to user home packages.";

    homeManager =
      {
        pkgs,
        lib,
        inputs',
        ...
      }:
      {
        home.packages =
          let
            system = pkgs.stdenv.hostPlatform.system;
            hmPackages = inputs'.home-manager.packages or { };
          in
          lib.optional (hmPackages ? ${system}) hmPackages.${system}.default;
      };
  };
}
