# MuseScore — music notation / score editor.
{ fleet, ... }:
{
  fleet.music._.production._.musescore = {
    description = "MuseScore music notation and score editor";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [ pkgs.musescore ];
      };
  };
}
