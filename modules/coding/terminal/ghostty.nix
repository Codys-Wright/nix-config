# Ghostty terminal emulator aspect
{
  FTS, ... }:
{
  FTS.coding._.terminals._.ghostty = {
    description = "Ghostty terminal emulator";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.ghostty
      ];
    };
  };
}

