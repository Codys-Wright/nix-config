{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.dusk-audio-plugins =
        pkgs.callPackage ../../packages/dusk-audio-plugins/dusk-audio-plugins.nix
          { };
    };
}
