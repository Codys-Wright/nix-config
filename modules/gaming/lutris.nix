# Lutris gaming platform aspect
{ ... }:
{
  den.aspects.lutris = {
    description = "Lutris gaming platform for managing Windows games on Linux";

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        lutris
      ];
    };
  };
}
