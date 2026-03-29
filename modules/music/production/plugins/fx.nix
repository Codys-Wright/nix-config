# Audio effects plugins
{
  FTS,
  ...
}:
{
  FTS.music._.production._.plugins._.fx = {
    description = "Audio effects plugins for music production";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux (
          with pkgs;
          [
            dragonfly-reverb
            lsp-plugins
          ]
        );
      };
  };
}
