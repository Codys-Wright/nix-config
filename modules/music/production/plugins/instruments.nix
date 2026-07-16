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
            pkgs.fleet-vcv-rack
            pkgs.floe
            pkgs.tiagolr-ripplerx
            pkgs.dumumub-0000006
          ]
        );
      };
  };
}
