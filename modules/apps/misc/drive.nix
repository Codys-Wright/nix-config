# Drive (FastTrackStudios/drive): the agent CLI (`drive`) and the node
# (`drive-node`), at a release tag.
#
# No nixpkgs follows: the release pushes exactly these store paths (built
# from the tag's own flake.lock) to fasttrackstudio.cachix.org, so a switch
# downloads them and compiles nothing. Following our nixpkgs would make new
# paths no cache has.
#
# macOS: (<fleet.apps.misc/drive-launchd> { user = "rat"; }) installs
# Drive.app from the release (packages/drive-app-release) and runs that
# account's agent (`drive serve`, its state in ~/.local/share/drive-agent)
# as a LaunchDaemon, from the release's macOS tarball (packages/drive-release).
#
# Bump: point the url at the new tag, `nix flake update drive`, and run
# packages/drive-release/update.sh <tag>; switch.
{ inputs, lib, ... }:
{
  flake-file.inputs.drive.url = lib.mkDefault "github:FastTrackStudios/drive/v26.11.8";

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
      description = "Drive's agent (drive serve) as a boot-time LaunchDaemon run as ${user}, and Drive.app";
      darwin =
        { lib, pkgs, ... }:
        let
          log = "${home}/Library/Logs/drive-agent.log";
          # What ran the agent before: the hand-installed LaunchAgent, then
          # (2026-11-24) a LaunchAgent running the agent from Drive.app. One
          # agent per state dir, so both are stopped before the daemon loads.
          legacy = "${home}/Library/LaunchAgents/app.fasttrackstudio.drive-agent.plist";
          oldAgent = "/Library/LaunchAgents/app.fasttrackstudio.drive.agent.plist";
        in
        {
          # `drive` on PATH (the CLI), from the release's tarball.
          environment.systemPackages = [ pkgs.drive-release ];

          # The agent from boot, whoever is logged in. Finder's Drive (the
          # File Provider extension) reaches it in its own folder, through
          # the extension's home-relative sandbox exception.
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

          # Drive.app (the desktop app, in the menu bar, and the File
          # Provider that puts Drive in Finder), copied into /Applications:
          # the system takes an app's extensions from a real install, not a
          # link into the store. Copied again only when the release changes.
          system.activationScripts.postActivation.text = lib.mkAfter ''
            app=${pkgs.drive-app-release}/Applications/Drive.app
            mark="/Library/Application Support/Drive/installed-from"
            if [ "$(cat "$mark" 2>/dev/null)" != "$app" ]; then
              echo "drive: installing Drive.app ${pkgs.drive-app-release.version}"
              rm -rf /Applications/Drive.app
              ditto "$app" /Applications/Drive.app
              chmod -R u+w /Applications/Drive.app
              mkdir -p "$(dirname "$mark")"
              echo "$app" >"$mark"
            fi
          '';

          # In the menu bar at login (the app's own "Open at Login" would
          # make a second entry: leave it off).
          launchd.agents.drive-app.serviceConfig = {
            Label = "app.fasttrackstudio.drive.app";
            ProgramArguments = [
              "/usr/bin/open"
              "-g"
              "-a"
              "/Applications/Drive.app"
              "--args"
              "--background"
            ];
            RunAtLoad = true;
          };

          system.activationScripts.preActivation.text = lib.mkAfter ''
            if [ -f ${oldAgent} ]; then
              echo "drive: replacing the agent's LaunchAgent with the LaunchDaemon"
              uid=$(id -u ${lib.escapeShellArg user})
              launchctl bootout "gui/$uid/app.fasttrackstudio.drive.agent" 2>/dev/null || true
              rm -f ${oldAgent}
              for _ in $(seq 60); do
                pgrep -f '/Applications/Drive.app/Contents/MacOS/drive serve' >/dev/null || break
                sleep 1
              done
              pkill -f '/Applications/Drive.app/Contents/MacOS/drive serve' 2>/dev/null || true
            fi
            if [ -f ${lib.escapeShellArg legacy} ]; then
              echo "drive: replacing ${user}'s hand-installed LaunchAgent"
              uid=$(id -u ${lib.escapeShellArg user})
              # Loaded from a login (gui) or over SSH (user): either domain.
              for domain in "gui/$uid" "user/$uid"; do
                launchctl bootout "$domain/app.fasttrackstudio.drive-agent" 2>/dev/null || true
              done
              mv ${lib.escapeShellArg legacy} ${lib.escapeShellArg "${legacy}.replaced-by-nix"}
              # Gone before the daemon loads: never two agents on one state dir.
              for _ in $(seq 30); do
                pgrep -u "$uid" -f ${lib.escapeShellArg "${home}/.local/bin/drive"} >/dev/null || break
                sleep 1
              done
              pkill -u "$uid" -f ${lib.escapeShellArg "${home}/.local/bin/drive"} 2>/dev/null || true
            fi
          '';
        };
    };
}
