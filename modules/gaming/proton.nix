# Proton compatibility tools aspect
{ ... }:
{
  den.aspects.proton = {
    description = "Proton compatibility tools for running Windows games on Linux";

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        protonup
      ];

      # AFTER THIS OPTION IS SET, RUN PROTONUP
      environment.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
    };
  };
}
