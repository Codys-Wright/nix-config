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
            (pkgs.callPackage ../../../../packages/qpitch/qpitch.nix { })
            (pkgs.callPackage ../../../../packages/dusk-audio-plugins/dusk-audio-plugins.nix { })
            (pkgs.callPackage ../../../../packages/aether/aether.nix { })
          ]
        );
      };
  };
}
