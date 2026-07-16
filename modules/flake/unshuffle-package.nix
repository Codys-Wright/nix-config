{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.unshuffle = pkgs.callPackage ../../packages/unshuffle/unshuffle.nix { };
    };
}
