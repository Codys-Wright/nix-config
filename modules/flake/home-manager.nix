{
  inputs,
  lib,
  den,
  __findFile,
  ...
}:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.hm = {
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

  # Forward host-aspect homeManager blocks to each user's home-manager config.
  # Den's built-in ctx pipeline only resolves the USER aspect for homeManager class.
  # Host-included aspects with homeManager blocks (niri, stylix, etc.) need
  # to be explicitly forwarded. This aspect uses host context to resolve the host
  # aspect for homeManager class and include those modules.
  den.aspects.hm-host-forward = <den.lib.parametric> {
    description = "Forwards homeManager blocks from host-included aspects to HM users";
    includes = [
      (
        { host, ... }:
        let
          hostAspect = den.aspects.${host.aspect};
          resolved = den.lib.aspects.resolve "homeManager" hostAspect;
        in
        {
          homeManager = _: { imports = resolved.imports; };
        }
      )
    ];
  };
}
