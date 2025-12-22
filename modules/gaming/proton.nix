# Proton compatibility tools aspect
{
  FTS.apps._.gaming._.proton = {
    description = "Proton compatibility tools for running Windows games on Linux";

    homeManager = {
      pkgs,
      lib,
      ...
    }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        home.packages = [pkgs.protonup-ng];
        home.sessionVariables = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
        };
      };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.protonup-ng pkgs.protonup-rs];

      # AFTER THIS OPTION IS SET, RUN PROTONUP
      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    };
  };
}
