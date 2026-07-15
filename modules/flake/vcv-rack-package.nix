{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.vcv-rack = pkgs.callPackage ../../packages/vcv-rack/vcv-rack.nix { };
    };
}
