# Firefox Browser aspect
{
  FTS, ... }:
{
  FTS.firefox = {
    description = "Firefox Browser";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.firefox
      ];
    };
  };
}

