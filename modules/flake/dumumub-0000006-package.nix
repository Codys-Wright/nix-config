{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.dumumub-0000006 = pkgs.callPackage ../../packages/dumumub-0000006/dumumub-0000006.nix { };
    };
}
