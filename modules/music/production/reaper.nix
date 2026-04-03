# Reaper DAW with extensions
# Uses fts-flake's custom reaper derivation (v7.66) instead of nixpkgs
{
  FTS,
  inputs,
  ...
}:
{
  flake-file.inputs.fts-flake.url = "path:/home/cody/Development/FastTrackStudio/fts-flake";
  flake-file.inputs.fts-flake.inputs.nixpkgs.follows = "nixpkgs";

  FTS.music._.production._.reaper = {
    description = "Reaper digital audio workstation with SWS and ReaPack extensions (v7.66 via fts-flake)";

    homeManager =
      { pkgs, ... }:
      let
        ftsPkgs = inputs.fts-flake.lib.mkFtsPackages {
          inherit pkgs;
          cfg = inputs.fts-flake.presets.full // {
            headless.enable = false;
          };
        };
      in
      {
        home.packages = [
          ftsPkgs.reaper
          pkgs.reaper-sws-extension
          pkgs.reaper-reapack-extension
        ];

        # Symlink REAPER extensions to UserPlugins directory
        home.file.".config/REAPER/UserPlugins/reaper_sws-x86_64.so".source =
          "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so";
        home.file.".config/REAPER/UserPlugins/reaper_reapack-x86_64.so".source =
          "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so";

        # Symlink SWS Python scripts
        home.file.".config/REAPER/Scripts/sws_python.py".source =
          "${pkgs.reaper-sws-extension}/Scripts/sws_python.py";
        home.file.".config/REAPER/Scripts/sws_python64.py".source =
          "${pkgs.reaper-sws-extension}/Scripts/sws_python64.py";
      };
  };
}
