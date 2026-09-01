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
            # Was packages/vcv-rack (an overrideAttrs vendoring a segfault patch
            # nixpkgs used to fetch from a since-deleted PR). nixpkgs 26.11 ships
            # the fix itself, and re-applying the vendored patch on top now
            # breaks the libRack.so link — so this is stock nixpkgs again.
            pkgs.vcv-rack
            pkgs.floe
            pkgs.tiagolr-ripplerx
            pkgs.dumumub-0000006
          ]
        );
      };
  };
}
