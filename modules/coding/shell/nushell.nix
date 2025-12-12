# Nushell shell aspect
{
  FTS, ... }:
{
  FTS.coding._.shells._.nushell = {
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

