# Lutris gaming platform aspect
{
  FTS,
  ...
}:
{
  FTS.apps._.gaming._.lutris = {
    description = "Lutris gaming platform for managing Windows games on Linux";

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.lutris ];
    };

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = [ pkgs.lutris ];
    };
  };
}
