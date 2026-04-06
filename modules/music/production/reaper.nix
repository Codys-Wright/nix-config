# Reaper DAW with extensions
# Uses reaper-flake's custom reaper derivation (v7.66) instead of nixpkgs
{
  fleet,
  inputs,
  ...
}:
{
  flake-file.inputs.reaper-flake.url = "github:FastTrackStudios/reaper-flake";
  flake-file.inputs.reaper-flake.inputs.nixpkgs.follows = "nixpkgs";

  fleet.music._.production._.reaper = {
    description = "Reaper digital audio workstation with SWS and ReaPack extensions (v7.66 via reaper-flake)";

    homeManager =
      { pkgs, ... }:
      let
        reaperPkgs = inputs.reaper-flake.lib.mkReaperPackages {
          inherit pkgs;
          cfg = inputs.reaper-flake.presets.full // {
            headless.enable = false;
          };
        };
      in
      {
        home.packages = [
          reaperPkgs.reaper
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
