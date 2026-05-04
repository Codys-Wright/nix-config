{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.opendeck = pkgs.callPackage ../../packages/opendeck/opendeck.nix { };
    };
}
