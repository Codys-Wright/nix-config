{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.libqatemcontrol = pkgs.callPackage ../../packages/libqatemcontrol/libqatemcontrol.nix { };
      packages.cuteatum = pkgs.callPackage ../../packages/cuteatum/cuteatum.nix { };
    };
}
