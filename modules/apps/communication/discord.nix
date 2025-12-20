# Brave Browser aspect
{
  FTS.apps._.communications._.discord = {
    description = "Discord";

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.equibop];
    };
    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.equibop];
    };
  };
}
