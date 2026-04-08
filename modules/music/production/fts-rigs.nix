# FTS REAPER rigs — self-contained wrapper commands for each rig.
# Installs fts-reaper, fts-keys, fts-drums, fts-bass, fts-guitar, fts-vocals
# as terminal commands. Each generates its own launch.json + icons on first run.
{
  fleet,
  inputs,
  ...
}:
{
  flake-file.inputs.fts-reaper-flake.url = "github:FastTrackStudios/fts-reaper-flake";

  fleet.music._.production._.ftsRigs = {
    description = ''
      FTS REAPER rigs (reaper, keys, drums, bass, guitar, vocals).
      Installs self-contained wrapper commands that launch separate REAPER
      instances. Each rig auto-generates its config and icons on first run.
    '';

    homeManager =
      { pkgs, ... }:
      let
        fts = inputs.fts-reaper-flake;
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        home.packages = [
          fts.packages.${system}.fts-rigs
        ];
      };
  };
}
