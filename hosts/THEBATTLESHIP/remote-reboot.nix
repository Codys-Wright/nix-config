# Rebooting THEBATTLESHIP from afar and coming back to a working desktop.
#
# - Autologin: SDDM logs cody into the Loft session once per boot, so the
#   user services (pipewire, cua-driver, sunshine, the Studio clock) and the
#   remote desktops are up without anyone at the keyboard. A logout still
#   lands on the login screen (SDDM's Relogin stays off).
# - `safe-reboot`: reboots only when nothing would be cut off — no GitHub
#   Actions job running on the runners, no nix build in flight — or waits
#   for that, or forces it.
{ den, ... }:
{
  den.aspects.THEBATTLESHIP-remote-reboot = {
    description = "Autologin into cody's session at boot, and safe-reboot: reboot once no CI job or nix build is running";
    nixos =
      { pkgs, ... }:
      let
        safe-reboot = pkgs.writeShellApplication {
          name = "safe-reboot";
          runtimeInputs = [
            pkgs.procps
            pkgs.coreutils
            pkgs.systemd
            pkgs.getent
          ];
          text = ''
            usage() {
              cat <<'EOF'
            safe-reboot            reboot now if nothing is busy, else say what is
            safe-reboot --wait     wait (checking every 30 s) until nothing is busy, then reboot
            safe-reboot --force    reboot whatever is running
            safe-reboot --check    only say what would hold a reboot up
            EOF
            }

            # What a reboot would cut off, one line each; nothing when idle.
            busy() {
              local jobs builds
              # A runner taking a job starts Runner.Worker; an idle one only
              # has its Listener.
              jobs=$(pgrep -c -f 'Runner\.Worker' || true)
              [ "''${jobs:-0}" -gt 0 ] && echo "$jobs GitHub Actions job(s) running"
              # nix builds run as the nixbld users.
              builds=$(pgrep -c -u "$(getent group nixbld | cut -d: -f4)" 2>/dev/null || true)
              [ "''${builds:-0}" -gt 0 ] && echo "nix builds in flight ($builds processes)"
              return 0
            }

            mode=''${1:-now}
            case "$mode" in
              -h | --help) usage; exit 0 ;;
              --check)
                out=$(busy)
                if [ -n "$out" ]; then echo "$out"; exit 1; fi
                echo "idle: a reboot would cut nothing off"
                exit 0
                ;;
              --force) ;;
              --wait)
                while out=$(busy) && [ -n "$out" ]; do
                  echo "$(date +%T) waiting: $out"
                  sleep 30
                done
                ;;
              now)
                out=$(busy)
                if [ -n "$out" ]; then
                  echo "not rebooting:"
                  echo "$out"
                  echo "(safe-reboot --wait to reboot once idle, --force to reboot anyway)"
                  exit 1
                fi
                ;;
              *) usage; exit 2 ;;
            esac

            echo "rebooting; cody's session logs itself back in"
            exec /run/wrappers/bin/sudo systemctl reboot
          '';
        };
      in
      {
        services.displayManager.autoLogin = {
          enable = true;
          user = "cody";
        };

        environment.systemPackages = [ safe-reboot ];
      };
  };
}
