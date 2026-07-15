# Virtual instrument plugins
{
  fleet,
  inputs,
  ...
}:
{
  fleet.music._.production._.plugins._.instruments = {
    description = "Virtual instrument plugins for music production";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux (
          (with pkgs; [
            vital
            cardinal
          ])
          ++ [
            (pkgs.callPackage ../../../../packages/vcv-rack/vcv-rack.nix { })
            (pkgs.callPackage ../../../../packages/floe/floe.nix {
              zig_0_14 = inputs.zig-overlay.packages.${pkgs.system}."0.14.0";
            })
          ]
        );
      };
  };
}
