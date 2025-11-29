# Firefox Browser aspect
{ ... }:
{
  den.aspects.firefox = {
    description = "Firefox Browser";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.firefox
      ];
    };
  };
}

