# FTS signal rigs — REAPER instances for live instrument capture
# Uses fts-reaper-flake's home-manager module to declaratively install
# per-rig launch configs, badge icons, and .desktop entries.
{
  fleet,
  inputs,
  ...
}:
{
  flake-file.inputs.fts-reaper-flake.url = "github:FastTrackStudios/fts-reaper-flake";

  fleet.music._.production._.ftsRigs = {
    description = ''
      FTS REAPER signal rigs (keys, drums, bass, guitar, vocals).
      Installs per-rig launch.json configs, badge icons, and .desktop entries
      via fts-reaper-flake. Each rig launches a separate REAPER instance with
      its own resources dir at ~/.fasttrackstudio/Reaper.
    '';

    homeManager =
      { pkgs, ... }:
      let
        fts = inputs.fts-reaper-flake;
        system = pkgs.stdenv.hostPlatform.system;

        # GUI build — presets.full has headless.enable = false
        prodPkgs = fts.lib.mkFtsPackages {
          inherit pkgs;
          cfg = fts.presets.full // {
            reaper.configDir = "$HOME/.fasttrackstudio/Reaper";
          };
        };
      in
      {
        imports = [ fts.homeManagerModules.default ];

        fts.reaper = {
          enable = true;
          package = prodPkgs.reaper;
          launcherPackage = fts.packages.${system}.reaper-launcher;

          # Enable all predefined signal rigs.
          # Toggle individually with rigs.keys, rigs.drums, etc.
          rigs.all = true;
        };
      };
  };
}
