# Deadlock Mod Manager — native build from upstream's flake
#
# Native rather than the Flatpak: the Flatpak sandbox hides host processes, so
# it polls for the game with `flatpak-spawn --host` over all of /proc, and one
# scan that exceeds its 5 s cap aborts the launch. The native build checks
# processes in-process and, on NixOS, starts Steam via the `steam` wrapper on
# PATH.
{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.deadlock-mod-manager.url = lib.mkDefault "github:deadlock-mod-manager/deadlock-mod-manager/v2.3.0";
  # nixpkgs is deliberately NOT followed: upstream's cargoHash / pnpm hash are
  # fixed-output hashes computed against its own locked nixpkgs.

  fleet.gaming._.deadlock-mod-manager = {
    description = "Deadlock Mod Manager (native build, upstream flake)";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [
          inputs.deadlock-mod-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
  };
}
