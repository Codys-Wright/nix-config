{ fleet, ... }:
{
  fleet.user._.launch-as = {
    description = "Install ego and a `launch-as` wrapper for running GUI apps as another local user in the current graphical session (Wayland/XWayland/PipeWire sockets + xdg-desktop-portal handled automatically)";

    nixos =
      { pkgs, ... }:
      {
        # Allow wheel users to open machinectl shells into other local
        # accounts without a password prompt. ego's default backend is
        # `machinectl shell`, which polkit gates on host-shell (and an
        # implied host-login). Both actions default to auth_admin, so we
        # whitelist them for wheel.
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if ((action.id == "org.freedesktop.machine1.host-shell" ||
                 action.id == "org.freedesktop.machine1.host-login" ||
                 action.id == "org.freedesktop.machine1.host-open-pty") &&
                subject.isInGroup("wheel")) {
              return polkit.Result.YES;
            }
          });
        '';

        environment.systemPackages = [
          pkgs.ego
          (pkgs.writeShellApplication {
            name = "launch-as";
            runtimeInputs = [
              pkgs.ego
              pkgs.acl
            ];
            text = ''
              if [ $# -lt 2 ]; then
                echo "usage: launch-as <user> <command> [args...]" >&2
                exit 64
              fi
              target="$1"
              shift

              # KWin/Xwayland creates /tmp/.X11-unix/X<n> mode 0755 (no write for
              # others), which blocks clients running under a different UID from
              # connect()ing. ego adds an xhost SI entry and relies on the
              # abstract socket fallback, but Steam's 32-bit bootstrap uses the
              # filesystem socket only. An ACL entry keyed to the target UID
              # doesn't help either because Steam's bwrap wraps the client in a
              # user namespace where bri→uid 0 and everyone else→nobody, so the
              # kernel matches the `other` bits, not the ACL entry.
              #
              # Pragmatic fix: chmod the socket to 0777. X-level auth (ego's
              # xhost SI:localuser:<target> entry) still gates who the server
              # accepts, so this is no weaker than a regular multi-user X session.
              if [ -n "''${DISPLAY:-}" ]; then
                xnum="''${DISPLAY#*:}"
                xnum="''${xnum%%.*}"
                sock="/tmp/.X11-unix/X''${xnum}"
                if [ -S "$sock" ]; then
                  chmod 0777 "$sock" 2>/dev/null || true
                fi
              fi

              # Share the Xauthority cookie so cookie-based clients work too.
              if [ -n "''${XAUTHORITY:-}" ] && [ -f "$XAUTHORITY" ]; then
                setfacl -m "u:''${target}:r" "$XAUTHORITY" 2>/dev/null || true
              fi

              exec ego -u "$target" -- "$@"
            '';
          })
        ];
      };
  };
}
