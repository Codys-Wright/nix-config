# Hermes on starcommand can see and drive cody's real niri desktop on request:
# the `battleship` profile's MCP servers run
# `ssh -l cody battleship hermes-desktop-mcp cuadriver|loft-mcp`, which joins
# cody's live graphical session and starts CuaDriver (native Wayland) or
# `loft mcp`. (The starcommand agent key already logs in as cody; Cody chose to
# keep that.) The agent user's private Bot Desktop is separate
# (fleet.system._.agent-bot-desktop).
{ inputs, ... }:
{
  den.aspects.THEBATTLESHIP-hermes-desktop.nixos =
    { pkgs, ... }:
    let
      cuaDriver = "${
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.pm-cua-driver
      }/cua-driver";
      # Join the running graphical session: WAYLAND_DISPLAY / DISPLAY (XWayland)
      # come from the user manager's environment, which niri exports into.
      launcher = pkgs.writeShellScriptBin "hermes-desktop-mcp" ''
        set -eu
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
        eval "$(${pkgs.systemd}/bin/systemctl --user show-environment \
          | ${pkgs.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|NIRI_SOCKET)=' \
          | ${pkgs.gnused}/bin/sed 's/^/export /')"
        if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
          echo "no graphical session for $(id -un) right now" >&2
          exit 1
        fi
        case "''${1:-cuadriver}" in
          cuadriver)
            export CUA_DRIVER_RS_ENABLE_WAYLAND=1 CUA_DRIVER_RS_TELEMETRY_ENABLED=0
            exec ${cuaDriver} mcp --no-overlay
            ;;
          loft-mcp)
            for loft in "$HOME/.nix-profile/bin/loft" "/etc/profiles/per-user/$(id -un)/bin/loft"; do
              [ -x "$loft" ] && exec "$loft" mcp
            done
            echo "loft is not installed for $(id -un)" >&2
            exit 1
            ;;
          *)
            echo "usage: hermes-desktop-mcp [cuadriver|loft-mcp]" >&2
            exit 1
            ;;
        esac
      '';
    in
    {
      environment.systemPackages = [ launcher ];
    };
}
