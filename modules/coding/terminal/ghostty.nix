# Ghostty terminal emulator aspect
{ ... }:
{
  den.aspects.ghostty = {
    description = "Ghostty terminal emulator";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.ghostty
      ];
    };
  };
}

