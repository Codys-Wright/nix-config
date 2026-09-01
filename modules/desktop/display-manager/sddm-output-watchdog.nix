# Recover SDDM from the "greeter lost its last DRM output" wedge.
#
# When the only connected output disappears from under the running Wayland
# greeter (monitor DPMS, an input switch on the display, a DP link retrain),
# kwin_wayland has nothing left to composite on and exits — cleanly, status 0.
# SDDM reads that clean exit as `SDDM::Auth::HELPER_SUCCESS`, i.e. "the greeter
# handed off to a user session", and moves into its wait-for-session state. No
# session ever appears, and SDDM never re-probes DRM when the connector comes
# back. The screen stays dark forever.
#
# Nothing in systemd's view is wrong: `display-manager.service` stays
# `active (running)` with a live main PID and `systemctl --failed` is empty, so
# `Restart=` on the unit cannot help — the service never exits, it wedges.
#
# Fix: on a DRM hotplug event, check whether the machine is actually wedged
# (display-manager up, but no greeter process AND no graphical session on
# seat0) and, only then, restart display-manager.
#
# Full incident writeup: docs/sddm-no-greeter-incident.md
{ fleet, ... }:
{
  fleet.desktop._.display-manager._.sddm-output-watchdog = {
    description = "Restart SDDM when a DRM output returns to a wedged (greeter-less) display manager";

    nixos =
      { pkgs, lib, ... }:
      let
        check = pkgs.writeShellScript "sddm-output-watchdog" ''
          set -u
          PATH=${
            lib.makeBinPath [
              pkgs.systemd
              pkgs.procps
              pkgs.coreutils
            ]
          }

          # Only act when the display manager is supposed to be up.
          systemctl is-active --quiet display-manager.service || exit 0

          # A greeter process alive means SDDM is fine — this is an ordinary
          # hotplug, leave it alone.
          pgrep -u sddm -f 'sddm-greeter' >/dev/null && exit 0

          # A real user session on seat0 means someone is logged in and
          # compositing; restarting the DM would kill their session. (Column
          # layout of `list-sessions` varies with systemd version, so read the
          # session ids from the first column and query each properly.)
          for s in $(loginctl list-sessions --no-legend | awk '{ print $1 }'); do
            eval "$(loginctl show-session "$s" -p Seat -p Class)"
            if [ "''${Seat:-}" = "seat0" ] && [ "''${Class:-}" = "user" ]; then
              exit 0
            fi
          done

          # display-manager active, no greeter, no user session on seat0:
          # SDDM is wedged waiting for a session that will never start.
          echo "sddm-output-watchdog: display-manager active with no greeter and no seat0 session; restarting."
          systemctl restart display-manager.service
        '';
      in
      {
        systemd.services.sddm-output-watchdog = {
          description = "Recover a wedged SDDM after a DRM output returns";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = check;
          };
          # Never let a hotplug storm turn into a DM restart loop.
          # (StartLimit* live in [Unit], not [Service].)
          unitConfig = {
            StartLimitIntervalSec = "5min";
            StartLimitBurst = 3;
          };
        };

        # DRM hotplug events arrive as `change` on the card device with
        # HOTPLUG=1. Pull the oneshot in via systemd rather than running
        # systemctl from a udev RUN= (which udev kills after its timeout).
        services.udev.extraRules = ''
          ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="sddm-output-watchdog.service"
        '';
      };
  };
}
