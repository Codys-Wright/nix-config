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
      # hermes-agent's pm lock pins cua-driver 0.21.0; run a newer release
      # through its own derivation (same unpack/install), swapping the source.
      cuaDriverVersion = "0.38.0";
      cuaDriverArtifacts = {
        x86_64-linux = {
          arch = "x86_64";
          sha256 = "31ab9709dd91ce73677e49b9f3e75c6f0d3e4d9625c286c9e58262bfbea698dd";
        };
        aarch64-linux = {
          arch = "arm64";
          sha256 = "80c9ae66bc7322052dd426c6133c96086b33894bf06c972bca8215384400b33d";
        };
      };
      cuaDriverPkg =
        inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.pm-cua-driver.overrideAttrs
          (_: {
            version = cuaDriverVersion;
            srcs = [
              (
                let
                  a = cuaDriverArtifacts.${pkgs.stdenv.hostPlatform.system};
                in
                pkgs.fetchurl {
                  url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${cuaDriverVersion}/cua-driver-rs-${cuaDriverVersion}-linux-${a.arch}-binary.tar.gz";
                  inherit (a) sha256;
                }
              )
            ];
          });
      cuaDriver = "${cuaDriverPkg}/cua-driver";
      # Join the running graphical session: WAYLAND_DISPLAY / DISPLAY (XWayland)
      # come from the user manager's environment, which niri exports into.
      joinSession = ''
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
        eval "$(${pkgs.systemd}/bin/systemctl --user show-environment \
          | ${pkgs.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|NIRI_SOCKET)=' \
          | ${pkgs.gnused}/bin/sed 's/^/export /')"
        if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
          echo "no graphical session for $(id -un) right now" >&2
          exit 1
        fi
      '';
      # The driver's own CLI (`cua-driver call …`, `skills install`, the route
      # the cua-driver agent skill prefers), joined to the same session
      # (fleet.coding._.cli._.cua-agent registers the MCP and the skills).
      cli = pkgs.writeShellScriptBin "cua-driver" ''
        set -eu
        ${joinSession}
        export CUA_DRIVER_RS_ENABLE_WAYLAND=1 CUA_DRIVER_RS_TELEMETRY_ENABLED=0
        exec ${cuaDriver} "$@"
      '';
      launcher = pkgs.writeShellScriptBin "hermes-desktop-mcp" ''
        set -eu
        ${joinSession}
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
      environment.systemPackages = [
        launcher
        cli
      ];

      # The daemon `cua-driver call …` talks to (~/.cache/cua-driver/
      # cua-driver.sock), up for cody's graphical session; the MCP route
      # (`hermes-desktop-mcp cuadriver`) runs its own and doesn't need it.
      systemd.user.services.cua-driver = {
        description = "CuaDriver daemon (computer use) for cody's desktop session";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        unitConfig.ConditionUser = "cody";
        serviceConfig = {
          ExecStart = "${cli}/bin/cua-driver serve";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
