# Nushell shell aspect
{
  FTS, ... }:
{
  FTS.nushell = {
    description = "Nushell shell package";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        nushell
      ];
    };

    homeManager = { pkgs, ... }: {
      programs.nushell = {
        enable = true;
      };
    };
  };
}

