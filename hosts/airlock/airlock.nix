{
  inputs,
  fleet,
  lib,
  __findFile,
  ...
}:

{

  den.hosts.aarch64-darwin = {
    airlock = {
      description = "An Mac Mini that holds all the proprietary garbage that can't run on linux";
    };
  };

  den.aspects.airlock = {
    darwin =
      { pkgs, ... }:
      {
        nix.enable = lib.mkForce false;
        nix.optimise.automatic = lib.mkForce false;
      };
  };

}
