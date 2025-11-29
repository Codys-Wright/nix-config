# Brave Browser aspect
{
  FTS, ... }:
{
  FTS.brave = {
    description = "Brave Browser";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.brave
      ];
    };
  };
}

