# FTS REAPER — one package installs rig wrappers, icons, and desktop entries.
{ fleet, inputs, ... }:
{
  flake-file.inputs.fts-reaper-flake.url = "github:FastTrackStudios/fts-reaper-flake";

  fleet.music._.production._.ftsRigs = {
    description = "FTS REAPER production environment";

    nixos =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        environment.systemPackages = [
          inputs.fts-reaper-flake.packages.${system}.fts-rigs
        ];
      };
  };
}
