# Proton compatibility tools aspect
{
  FTS, ... }:
{
  FTS.proton = {
    description = "Proton compatibility tools for running Windows games on Linux";

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        protonup-ng
      ];

      # AFTER THIS OPTION IS SET, RUN PROTONUP
      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    };
  };
}
