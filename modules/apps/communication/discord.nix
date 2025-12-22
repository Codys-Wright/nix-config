# Brave Browser aspect
{
  FTS.apps._.communications._.discord = {
    description = "Discord";

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = lib.mkIf (!pkgs.stdenv.isDarwin) [pkgs.equibop];
    };
    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.equibop];
    };
  };
}
