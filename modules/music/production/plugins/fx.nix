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
            (pkgs.callPackage ../../../../packages/tiagolr/time12.nix { })
            (pkgs.callPackage ../../../../packages/tiagolr/filtr.nix { })
            (pkgs.callPackage ../../../../packages/tiagolr/reevr.nix { })
            (pkgs.callPackage ../../../../packages/tiagolr/gate12.nix { })
          ]
        );
      };
  };
}
