# Deadlock Mod Manager — native nixpkgs build, from a dedicated unstable input
#
# Native rather than the Flatpak: the Flatpak sandbox hides host processes, so
# it polls for the game with `flatpak-spawn --host` over all of /proc, and one
# scan that exceeds its 5 s cap aborts the launch. The native build checks
# processes in-process and, on NixOS, starts Steam via the `steam` wrapper on
# PATH.
#
# The mod manager moves fast and the fleet's pinned nixpkgs lags it (1.1.0 vs
# 2.3.0 at the time of writing), so it tracks nixos-unstable through its own
# input — same pattern as nixpkgs-pipewire — leaving the rest of the system's
# nixpkgs alone. Hydra builds it, so it comes from the binary cache.
{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.nixpkgs-deadlock-mod-manager.url = lib.mkDefault "github:nixos/nixpkgs/nixos-unstable";

  fleet.gaming._.deadlock-mod-manager = {
    description = "Deadlock Mod Manager (native build, dedicated nixos-unstable input)";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [
          inputs.nixpkgs-deadlock-mod-manager.legacyPackages.${pkgs.stdenv.hostPlatform.system}.deadlock-mod-manager
        ];
      };
  };
}
