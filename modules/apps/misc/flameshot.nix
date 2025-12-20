# Flameshot aspect
{
  FTS.apps._.misc._.flameshot = {
    description = "Flameshot - Powerful yet simple to use screenshot software";

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.flameshot];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.flameshot];
    };
  };
}
