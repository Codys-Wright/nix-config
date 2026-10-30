# CuaDriver for a niri (Wayland) desktop session: the pinned driver build and
# a `cua-driver` CLI that joins the calling user's live graphical session.
# Shared by <fleet.system/cua-desktop> and THEBATTLESHIP's Hermes launcher.
{ inputs, pkgs }:
let
  # hermes-agent's pm lock pins cua-driver 0.21.0; run a newer release
  # through its own derivation (same unpack/install), swapping the source.
  version = "0.38.0";
  artifacts = {
    x86_64-linux = {
      arch = "x86_64";
      sha256 = "31ab9709dd91ce73677e49b9f3e75c6f0d3e4d9625c286c9e58262bfbea698dd";
    };
    aarch64-linux = {
      arch = "arm64";
      sha256 = "80c9ae66bc7322052dd426c6133c96086b33894bf06c972bca8215384400b33d";
    };
  };
  package =
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.pm-cua-driver.overrideAttrs
      (_: {
        inherit version;
        srcs = [
          (
            let
              a = artifacts.${pkgs.stdenv.hostPlatform.system};
            in
            pkgs.fetchurl {
              url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${version}/cua-driver-rs-${version}-linux-${a.arch}-binary.tar.gz";
              inherit (a) sha256;
            }
          )
        ];
      });
in
rec {
  bin = "${package}/cua-driver";

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
    exec ${bin} "$@"
  '';
}
