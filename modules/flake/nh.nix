# nh aspect - Nix helper tool for managing NixOS/Nix-darwin configurations
{
  FTS, ... }:
{
  FTS.nh = {
    description = "Nix helper tool (nh) for managing NixOS/Nix-darwin configurations";

    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nh ];
    };

    darwin = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.nh ];
    };
  };
}

