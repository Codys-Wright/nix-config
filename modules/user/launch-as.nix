{ fleet, ... }:
{
  fleet.user._.launch-as = {
    description = "Install ego and a `launch-as` wrapper for running GUI apps as another local user in the current graphical session (Wayland/XWayland/PipeWire sockets + xdg-desktop-portal handled automatically)";

    nixos =
      { pkgs, ... }:
      {
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

              # KWin/Xwayland creates the named X socket with mode 0755 (no write for
              # others). ego adds an xhost SI entry and relies on abstract-socket
              # fallback, which modern libX11 uses — but Steam's 32-bit bootstrap
              # connects via the filesystem socket only and fails with
              # "XOpenDisplay failed". Grant the target user rw on the named socket.
              if [ -n "''${DISPLAY:-}" ]; then
                xnum="''${DISPLAY#*:}"
                xnum="''${xnum%%.*}"
                sock="/tmp/.X11-unix/X''${xnum}"
                if [ -S "$sock" ]; then
                  setfacl -m "u:''${target}:rw" "$sock" 2>/dev/null || true
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
