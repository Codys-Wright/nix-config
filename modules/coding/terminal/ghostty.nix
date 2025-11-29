# Ghostty terminal emulator aspect
{
  FTS, ... }:
{
  FTS.ghostty = {
    description = "Ghostty terminal emulator";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.ghostty
      ];
    };
  };
}

