# Hourly bounded sweep of the warm Cargo target dirs on the Development drive.
#
# The drive is shared by the canonical checkouts and the CI runners. Builds
# fill it: task/target took the drive from 300G free to 0 B in under three
# hours (2026-10-21, 226G of it in target/debug/incremental). Before this
# timer existed, a human had to run `cargo sweep` by hand.
#
# Each run:
#   1. logs df of the drive;
#   2. takes the host build lease (~agent/.local/bin/build-lease, the same
#      lease every agent build holds) and SKIPS the run if it is BUSY, so it
#      never touches a tree that is mid-build;
#   3. also skips a project when one of its cargo locks (.cargo-lock /
#      .cargo-build-lock) is held, which catches a build run without the lease;
#   4. runs `cargo sweep --maxsize <N>GB` as the target dir's owner (cody);
#   5. prunes the oldest incremental crate dirs until the target dir is under
#      the same budget. cargo-sweep 0.8 cannot map `incremental/<crate>-<hash>`
#      dirs to a fingerprint, so it never deletes them: after the manual sweep
#      task/target was still 250G, 226G of it incremental. Dirs touched in the
#      last `keepMinutes` are kept. A pruned dir only costs that crate an
#      incremental cold start; rustc recreates it;
#   6. releases the lease and logs df again.
#
# Additive only: it deletes build output under <project>/target, nothing
# else. It never runs `cargo clean`.
#
# Logs: journalctl -u dev-target-sweep. Run once by hand:
#   systemctl start dev-target-sweep
# Pause it: systemctl stop dev-target-sweep.timer
# Remove it: drop den.aspects.THEBATTLESHIP-target-sweep from
# THEBATTLESHIP.nix and switch.
{ den, ... }:
{
  den.aspects.THEBATTLESHIP-target-sweep = {
    description = "Hourly bounded cargo sweep of the Development drive's warm target dirs, under the build lease";
    nixos =
      { lib, pkgs, ... }:
      let
        drive = "/run/media/Development";
        lease = "/home/agent/.local/bin/build-lease";
        leaseOwner = "dev-target-sweep";
        # The agent user holds the lease and prunes incremental dirs. Its
        # write ACL covers the whole drive outside the CI dirs, including
        # files cody created. cody cannot delete inside agent-owned dirs
        # (there is no user:cody ACL entry), so the prune does not run as cody.
        pruneUser = "agent";
        # Projects whose <path>/target is bounded. maxGB is the size the target
        # dir is brought back down to every hour, which leaves room to build.
        # The budget is the one the Captain approved for the manual sweep.
        projects = [
          {
            path = "${drive}/task";
            maxGB = 200;
          }
          # fts/studio/target is 837G (623G incremental) and wrote ~130G in
          # the same three hours. It is not swept until the Captain picks a
          # budget for it, e.g.:
          # { path = "${drive}/fts/studio"; maxGB = 300; }
        ];
        # Incremental dirs written in this window are never pruned, so a
        # build that just finished keeps its warm cache.
        keepMinutes = 120;

        prune = pkgs.writeShellApplication {
          name = "dev-target-prune-incremental";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.findutils
          ];
          text = ''
            # usage: dev-target-prune-incremental <target-dir> <maxGB> <keepMinutes>
            target=$1
            max_kib=$(( $2 * 1024 * 1024 ))
            keep=$3
            total=$(du -sk "$target" 2>/dev/null | cut -f1) || true
            total=''${total:-0}
            echo "prune: $target is $(( total / 1024 / 1024 ))G, budget $2G"
            if [ "$total" -le "$max_kib" ]; then
              echo "prune: under budget, nothing to do"
              exit 0
            fi
            excess=$(( total - max_kib ))
            removed=0
            freed=0
            failed=0
            # <target>/<profile>/incremental and <target>/<triple>/<profile>/incremental,
            # oldest crate dir first. Only plain directories directly under an
            # incremental dir are candidates; symlinks are never followed.
            while IFS= read -r dir; do
              [ "$excess" -gt 0 ] || break
              size=$(du -sk "$dir" 2>/dev/null | cut -f1) || size=0
              if rm -rf --one-file-system -- "$dir" 2>/dev/null; then
                removed=$(( removed + 1 ))
                freed=$(( freed + size ))
                excess=$(( excess - size ))
              else
                failed=$(( failed + 1 ))
              fi
            done < <(
              find "$target" -mindepth 2 -maxdepth 3 -type d -name incremental -print0 |
                xargs -0 -r -I{} find {} -mindepth 1 -maxdepth 1 -type d -mmin +"$keep" -printf '%T@ %p\n' |
                sort -n | cut -d' ' -f2-
            )
            echo "prune: removed $removed incremental dirs, freed $(( freed / 1024 / 1024 ))G, $failed failed"
            if [ "$excess" -gt 0 ]; then
              echo "prune: still $(( excess / 1024 / 1024 ))G over budget (only dirs older than ''${keep}m are pruned)"
            fi
          '';
        };

        sweepProject =
          p:
          let
            target = "${p.path}/target";
          in
          ''
            sweep_project ${lib.escapeShellArg p.path} ${lib.escapeShellArg target} ${toString p.maxGB}
          '';

        sweep = pkgs.writeShellApplication {
          name = "dev-target-sweep";
          runtimeInputs = [
            pkgs.cargo
            pkgs.cargo-sweep
            pkgs.coreutils
            pkgs.findutils
            pkgs.util-linux # runuser, flock
          ];
          text = ''
            drive=${drive}
            lease=${lease}
            owner=${leaseOwner}

            df_line() { df -h --output=size,used,avail,pcent "$drive" | tail -1; }

            mountpoint -q "$drive" || { echo "SKIP: $drive is not mounted"; exit 0; }
            echo "df before: $(df_line)"

            if [ ! -x "$lease" ]; then
              echo "SKIP: $lease is missing, so the sweep cannot take the build lease"
              exit 0
            fi
            if ! runuser -u ${pruneUser} -- "$lease" acquire "$owner" 3600; then
              echo "SKIP: build lease is BUSY"
              exit 0
            fi
            trap 'runuser -u ${pruneUser} -- "$lease" release "$owner" || true; echo "df after: $(df_line)"' EXIT

            sweep_project() {
              local proj=$1 target=$2 max=$3
              if [ ! -d "$target" ]; then
                echo "$proj: no target dir, skipping"
                return 0
              fi
              # A cargo build that ignored the lease still holds its locks.
              local f fd
              local -a fds=()
              while IFS= read -r f; do
                exec {fd}<"$f"
                fds+=("$fd")
                if ! flock -n -x "$fd"; then
                  echo "$proj: SKIP, $f is held (a cargo build is running)"
                  for fd in "''${fds[@]}"; do exec {fd}<&-; done
                  return 0
                fi
              done < <(find "$target" -maxdepth 3 -type f \( -name .cargo-lock -o -name .cargo-build-lock \))

              local who
              who=$(stat -c %U "$target")
              echo "$proj: cargo sweep --maxsize ''${max}GB as $who"
              # cargo-sweep wants a manifest; pointing it at a throwaway package
              # with CARGO_TARGET_DIR set (as the CI runner sweep does) means it
              # never resolves the real workspace or fetches its git deps.
              # CARGO_TARGET_DIR is set only for this sweep, never for a build.
              local pkg
              pkg=$(mktemp -d)
              mkdir "$pkg/src"
              printf '[package]\nname = "sweep"\nversion = "0.0.0"\nedition = "2021"\n' > "$pkg/Cargo.toml"
              echo 'fn main() {}' > "$pkg/src/main.rs"
              chown -R "$who" "$pkg"
              runuser -u "$who" -- env HOME="$(getent passwd "$who" | cut -d: -f6)" CARGO_TARGET_DIR="$target" \
                cargo sweep --maxsize "''${max}GB" "$pkg" 2>&1 |
                grep -v '^\[WARN\] Failed to remove' || true
              rm -rf -- "$pkg"

              runuser -u ${pruneUser} -- ${lib.getExe prune} "$target" "$max" ${toString keepMinutes} || true

              for fd in "''${fds[@]}"; do exec {fd}<&-; done
            }

            ${lib.concatMapStrings sweepProject projects}
          '';
        };
      in
      {
        systemd.services.dev-target-sweep = {
          description = "Bounded cargo sweep of the Development drive's warm target dirs (under the build lease)";
          unitConfig.RequiresMountsFor = drive;
          serviceConfig = {
            Type = "oneshot";
            # root only to switch users: the lease and the prune run as agent,
            # cargo sweep as the target dir's owner.
            ExecStart = lib.getExe sweep;
            Nice = 19;
            IOSchedulingClass = "idle";
            TimeoutStartSec = "50min";
          };
        };
        systemd.timers.dev-target-sweep = {
          description = "Hourly bounded cargo sweep of the Development drive";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "hourly";
            RandomizedDelaySec = "5min";
            Persistent = false;
          };
        };
      };
  };
}
