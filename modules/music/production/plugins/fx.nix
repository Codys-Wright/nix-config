# Audio effects plugins
{
  fleet,
  ...
}:
{
  fleet.music._.production._.plugins._.fx = {
    description = "Audio effects plugins for music production";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux (
          (with pkgs; [
            dragonfly-reverb
            lsp-plugins
            zlequalizer
            zlcompressor
            zlsplitter
          ])
          ++ [
            pkgs.qpitch
            pkgs.dusk-audio-plugins
            pkgs.aether
            pkgs.tiagolr-time12
            pkgs.tiagolr-filtr
            pkgs.tiagolr-reevr
            pkgs.tiagolr-gate12
          ]
        );
      };
  };
}
