# FTS REAPER — one package installs rig wrappers, icons, and desktop entries.
{ fleet, inputs, ... }:
{
  flake-file.inputs.fts-reaper-flake.url = "github:FastTrackStudios/fts-reaper-flake";
  # Use our updated reaper-flake (REAPER 7.75) for the launched fts-reaper,
  # instead of the older reaper pinned inside fts-reaper-flake.
  flake-file.inputs.fts-reaper-flake.inputs.reaper-flake.follows = "reaper-flake";
  # fts-reaper-flake's own lock pins a daw commit that was force-pushed away
  # upstream; lock daw ourselves so `nix flake update` can't reintroduce it.
  flake-file.inputs.daw = {
    url = "github:FastTrackStudios/daw";
    flake = false;
  };
  flake-file.inputs.fts-reaper-flake.inputs.daw.follows = "daw";

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
