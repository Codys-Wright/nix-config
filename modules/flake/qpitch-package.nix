{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.qpitch = pkgs.callPackage ../../packages/qpitch/qpitch.nix { };
    };
}
