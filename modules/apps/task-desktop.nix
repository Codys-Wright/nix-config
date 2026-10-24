# Task desktop (github:FastTrackStudios/task, `.#task-desktop`) on a NixOS
# host, always at the newest Task RELEASE tag (vX.Y.Z), never dev.
#
# Why a follower and not a flake input: Task's in-app updater is macOS-only
# (apps/desktop/src/updater.rs), so on NixOS the fleet updates it. Pinning
# Task as a nix-fleet input would turn every Task release into a host
# rebuild + a Captain-gated switch of the whole system (and a lock bump in
# cody's working tree). Instead the host carries a small timer that
# resolves the newest `v*` release tag and builds that tag's `task-desktop`
# into its own nix profile, /nix/var/nix/profiles/task-desktop. The host
# closure never changes on a Task release; only that profile moves.
#   - pinned:   the profile is built from `github:FastTrackStudios/task/<tag>`;
#               /var/lib/task-desktop-follow/{tag,rev} record which.
#   - cache:    fasttrackstudio.cachix.org is already a substituter
#               (modules/config/nix-settings.nix); when the Task release
#               pushes task-desktop there, the follower only downloads.
#               Otherwise it builds once per release in the nix store
#               (root disk), never in the Development drive.
#   - rollback: `nix profile rollback --profile /nix/var/nix/profiles/task-desktop`
#               (generations are pruned by the 7-day nix.gc).
#   - status:   `systemctl status task-desktop-follow`, `journalctl -u task-desktop-follow`.
#
# Usage: (fleet.apps._.task-desktop { user = "cody"; })
{ lib, ... }:
{
  fleet.apps._.task-desktop.description = "Task desktop app, following the newest Task release tag (NixOS)";

  fleet.apps._.task-desktop.__functor =
    _self:
    {
      user ? "cody",
      # How often to look for a new release tag.
      onCalendar ? "hourly",
      # Cap a from-source build (cache miss) so it can't take the whole box.
      buildCores ? 8,
      ...
    }:
    {
      nixos =
        { pkgs, config, ... }:
        let
          profile = "/nix/var/nix/profiles/task-desktop";
          stateDir = "/var/lib/task-desktop-follow";
          repo = "https://github.com/FastTrackStudios/task";

          follow = pkgs.writeShellApplication {
            name = "task-desktop-follow";
            runtimeInputs = with pkgs; [
              coreutils
              git
              gnugrep
              gnused
              jq
              config.nix.package
            ];
            text = ''
              # Newest release tag: exact vMAJOR.MINOR.PATCH only (skips the
              # macOS-only desktop-v* tags and any pre-release suffixes).
              latest="$(git ls-remote --tags --refs ${repo} 'v*' \
                | sed -n 's#.*refs/tags/##p' \
                | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
                | sort -V | tail -n 1)"
              if [ -z "$latest" ]; then
                echo "no Task release tag found at ${repo}" >&2
                exit 1
              fi

              current="$(cat ${stateDir}/tag 2>/dev/null || true)"
              if [ "$latest" = "$current" ] && [ -e ${profile} ] && [ "''${1:-}" != "--force" ]; then
                echo "Task desktop is current: $current ($(readlink -f ${profile}))"
                exit 0
              fi

              ref="github:FastTrackStudios/task/$latest"
              rev="$(nix flake metadata --json "$ref" | jq -r '.revision // .locked.rev')"
              echo "Task desktop: ''${current:-none} -> $latest ($rev)"
              # Build by commit, so the profile is exactly that tag's tree.
              nix build --option cores ${toString buildCores} --option max-jobs 1 \
                --profile ${profile} "github:FastTrackStudios/task/$rev#task-desktop"

              printf '%s\n' "$latest" > ${stateDir}/tag.new && mv ${stateDir}/tag.new ${stateDir}/tag
              printf '%s\n' "$rev" > ${stateDir}/rev.new && mv ${stateDir}/rev.new ${stateDir}/rev
              echo "Task desktop now $latest: $(readlink -f ${profile})"
            '';
          };

          # The launcher the desktop entry runs: always the current profile, so a
          # new release takes effect on the next launch.
          launcher = pkgs.writeShellScriptBin "task-desktop" ''
            app=${profile}/bin/task-app-desktop
            if [ ! -x "$app" ]; then
              echo "Task desktop is not installed yet (see: systemctl status task-desktop-follow)" >&2
              exit 1
            fi
            exec "$app" "$@"
          '';

          icon = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/FastTrackStudios/task/v0.2.3/apps/web/assets/icon-512.png";
            sha256 = "1j524nbp1pq7ca6ivsbi3fbpi8cn5fpwn1bnk07j4hbagfnhhg2r";
          };

          desktopItem = pkgs.makeDesktopItem {
            name = "task";
            desktopName = "Task";
            genericName = "Tasks, projects and calendar";
            comment = "Local-first vault, tasks, projects and calendar";
            exec = "task-desktop";
            icon = "${icon}";
            categories = [
              "Office"
              "ProjectManagement"
            ];
            startupWMClass = "task-app-desktop";
          };
        in
        {
          users.users.${user}.packages = [
            launcher
            desktopItem
          ];

          environment.systemPackages = [ follow ];

          systemd.services.task-desktop-follow = {
            description = "Follow the newest Task release tag for the Task desktop app";
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = lib.getExe follow;
              StateDirectory = "task-desktop-follow";
              Nice = 19;
              IOSchedulingClass = "idle";
              TimeoutStartSec = "3h";
            };
          };

          systemd.timers.task-desktop-follow = {
            description = "Look for a new Task release";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "5min";
              OnCalendar = onCalendar;
              RandomizedDelaySec = "10min";
              Persistent = true;
            };
          };
        };
    };
}
