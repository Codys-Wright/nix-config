# Brave Browser aspect
{ ... }:
{
  den.aspects.brave = {
    description = "Brave Browser";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.brave
      ];
    };
  };
}

