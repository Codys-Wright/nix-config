{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.aether = pkgs.callPackage ../../packages/aether/aether.nix { };
    };
}
