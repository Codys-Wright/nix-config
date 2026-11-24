# Drive (FastTrackStudios/drive): the agent CLI (`drive`) and the node
# (`drive-node`), at a release tag.
#
# No nixpkgs follows: the release pushes exactly these store paths (built
# from the tag's own flake.lock) to fasttrackstudio.cachix.org, so a switch
# downloads them and compiles nothing. Following our nixpkgs would make new
# paths no cache has.
#
# macOS: (<fleet.apps.misc/drive-launchd> { user = "rat"; }) runs that
# account's agent (`drive serve`, its state in ~/.local/share/drive-agent)
# as a LaunchDaemon, from the release's macOS tarball (packages/drive-release).
#
# Bump: point the url at the new tag, `nix flake update drive`, and run
# packages/drive-release/update.sh <tag>; switch.
{ inputs, lib, ... }:
{
  flake-file.inputs.drive.url = lib.mkDefault "github:FastTrackStudios/drive/v26.11.2";

  fleet.apps._.misc._.drive = {
    description = "Drive CLI (the agent, `drive`) from the release's Nix package";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [ inputs.drive.packages.${pkgs.stdenv.hostPlatform.system}.drive ];
      };
  };

  fleet.apps._.misc._.drive-launchd.__functor =
    _self:
    {
      # The macOS account whose agent this is (its ~/.local/share/drive-agent).
      user,
      home ? "/Users/${user}",
      ...
    }:
    {
      name = "drive-launchd(${user})";
      description = "Drive's agent (drive serve) as a boot-time LaunchDaemon run as ${user}";
      darwin =
        { lib, pkgs, ... }:
        let
          log = "${home}/Library/Logs/drive-agent.log";
          # The hand-installed LaunchAgent this replaces: one agent per
          # state dir, so it is stopped and set aside before the daemon loads.
          legacy = "${home}/Library/LaunchAgents/app.fasttrackstudio.drive-agent.plist";
        in
        {
          environment.systemPackages = [ pkgs.drive-release ];

          launchd.daemons.drive-agent.serviceConfig = {
            Label = "app.fasttrackstudio.drive";
            ProgramArguments = [
              (lib.getExe pkgs.drive-release)
              "serve"
            ];
            UserName = user;
            RunAtLoad = true;
            KeepAlive = true;
            ThrottleInterval = 10;
            EnvironmentVariables = {
              HOME = home;
              RUST_LOG = "drive_agent=info,drive=info,drive_native=warn";
            };
            StandardOutPath = log;
            StandardErrorPath = log;
          };

          system.activationScripts.preActivation.text = lib.mkAfter ''
            if [ -f ${lib.escapeShellArg legacy} ]; then
              echo "drive: replacing ${user}'s hand-installed LaunchAgent with the LaunchDaemon"
              uid=$(id -u ${lib.escapeShellArg user})
              launchctl bootout "gui/$uid/app.fasttrackstudio.drive-agent" 2>/dev/null || true
              mv ${lib.escapeShellArg legacy} ${lib.escapeShellArg "${legacy}.replaced-by-nix"}
            fi
          '';
        };
    };
}
