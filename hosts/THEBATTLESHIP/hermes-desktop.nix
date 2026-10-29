# Hermes on starcommand can see and drive cody's real niri desktop on request:
# the `battleship` profile's MCP servers run
# `ssh -l cody battleship hermes-desktop-mcp cuadriver|loft-mcp`, which joins
# cody's live graphical session and starts CuaDriver (native Wayland) or
# `loft mcp`. (The starcommand agent key already logs in as cody; Cody chose to
# keep that.) The agent user's private Bot Desktop is separate
# (fleet.system._.agent-bot-desktop). The `cua-driver` CLI and daemon come
# from <fleet.system/cua-desktop>.
{ inputs, ... }:
{
  den.aspects.THEBATTLESHIP-hermes-desktop.nixos =
    { pkgs, ... }:
    let
      cua = import ../../modules/system/_cua-driver.nix { inherit inputs pkgs; };
      launcher = pkgs.writeShellScriptBin "hermes-desktop-mcp" ''
        set -eu
        ${cua.joinSession}
        case "''${1:-cuadriver}" in
          cuadriver)
            export CUA_DRIVER_RS_ENABLE_WAYLAND=1 CUA_DRIVER_RS_TELEMETRY_ENABLED=0
            exec ${cua.bin} mcp --no-overlay
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
