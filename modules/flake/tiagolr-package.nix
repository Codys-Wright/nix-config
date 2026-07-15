{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.time12 = pkgs.callPackage ../../packages/tiagolr/time12.nix { };
      packages.filtr = pkgs.callPackage ../../packages/tiagolr/filtr.nix { };
      packages.reevr = pkgs.callPackage ../../packages/tiagolr/reevr.nix { };
      packages.gate12 = pkgs.callPackage ../../packages/tiagolr/gate12.nix { };
      packages.ripplerx = pkgs.callPackage ../../packages/tiagolr/ripplerx.nix { };
    };
}
