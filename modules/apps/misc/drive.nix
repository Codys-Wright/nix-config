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
# from inside it, as a LaunchAgent; the CLI is the release's tarball
# (packages/drive-release).
#
# Bump: point the url at the new tag, `nix flake update drive`, and run
# packages/drive-release/update.sh <tag>; switch.
{ inputs, lib, ... }:
{
  flake-file.inputs.drive.url = lib.mkDefault "github:FastTrackStudios/drive/v26.11.7";

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
      description = "Drive.app and its agent (drive serve) in ${user}'s session";
      darwin =
        { lib, pkgs, ... }:
        let
          log = "${home}/Library/Logs/drive-agent.log";
          agentLabel = "app.fasttrackstudio.drive.agent";
          # What ran the agent before: the hand-installed LaunchAgent, then
          # a LaunchDaemon running the release's bare binary. One agent per
          # state dir, so both are stopped before this one loads.
          legacy = "${home}/Library/LaunchAgents/app.fasttrackstudio.drive-agent.plist";
          oldDaemon = "/Library/LaunchDaemons/app.fasttrackstudio.drive.plist";
        in
        {
          # `drive` on PATH (the CLI), from the release's tarball.
          environment.systemPackages = [ pkgs.drive-release ];

          # The agent is Drive.app's own (Contents/MacOS/drive), in the
          # user's session: macOS 15 lets only Drive.app's code, there, into
          # the app group's folder, where the agent serves the socket
          # Finder's Drive (the File Provider) uses. A LaunchDaemon, or the
          # bare binary, is refused. So it runs while ${user} is logged in.
          # Any other account that logs in gets no agent (exit 0, not kept
          # alive).
          launchd.agents.drive-agent.serviceConfig = {
            Label = agentLabel;
            ProgramArguments = [
              "/bin/sh"
              "-c"
              ''[ "$(id -un)" = ${lib.escapeShellArg user} ] || exit 0; exec /Applications/Drive.app/Contents/MacOS/drive serve''
            ];
            LimitLoadToSessionType = "Aqua";
            RunAtLoad = true;
            KeepAlive.SuccessfulExit = false;
            ThrottleInterval = 10;
            EnvironmentVariables.RUST_LOG = "drive_agent=info,drive=info,drive_native=warn";
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
              # The agent runs from the app: onto the new one.
              uid=$(id -u ${lib.escapeShellArg user})
              launchctl kickstart -k "gui/$uid/${agentLabel}" 2>/dev/null || true
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
            if [ -f ${oldDaemon} ]; then
              echo "drive: replacing the agent's LaunchDaemon with Drive.app's agent"
              launchctl bootout system/app.fasttrackstudio.drive 2>/dev/null || true
              rm -f ${oldDaemon}
              for _ in $(seq 30); do
                pgrep -f 'drive-release-[^/]*/bin/drive serve' >/dev/null || break
                sleep 1
              done
              pkill -f 'drive-release-[^/]*/bin/drive serve' 2>/dev/null || true
            fi
            if [ -f ${lib.escapeShellArg legacy} ]; then
              echo "drive: replacing ${user}'s hand-installed LaunchAgent"
              uid=$(id -u ${lib.escapeShellArg user})
              # Loaded from a login (gui) or over SSH (user): either domain.
              for domain in "gui/$uid" "user/$uid"; do
                launchctl bootout "$domain/app.fasttrackstudio.drive-agent" 2>/dev/null || true
              done
              mv ${lib.escapeShellArg legacy} ${lib.escapeShellArg "${legacy}.replaced-by-nix"}
              # Gone before the new agent loads: never two agents on one state dir.
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
