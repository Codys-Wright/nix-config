# Standalone niri package with the plain KDL config tree embedded.
# Run with: nix run .#niri
#
# The same modules/desktop/environment/niri/_config tree is used by Home Manager
# as an editable out-of-store symlink and copied into this package for portable runs.
{
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      niriConfig = ../desktop/environment/niri/_config;
    in
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.niri = pkgs.writeShellApplication {
        name = "niri";
        runtimeInputs = with pkgs; [
          bash
          flameshot
          ghostty
          grim
          jq
          kitty
          librewolf
          niri
          noctalia-shell
          procps
          slurp
          swappy
          swaybg
          swaylock
          wireplumber
          wl-clipboard
          wlr-which-key
          xwayland-satellite
        ];
        text = ''
          export NIRI_CONFIG_DIR=${niriConfig}
          case "''${1-}" in
            validate)
              shift
              exec ${lib.getExe pkgs.niri} validate -c "${niriConfig}/config.kdl" "$@"
              ;;
            msg|panic|completions|help)
              exec ${lib.getExe pkgs.niri} "$@"
              ;;
            *)
              exec ${lib.getExe pkgs.niri} -c "${niriConfig}/config.kdl" "$@"
              ;;
          esac
        '';
      };
    };
}
