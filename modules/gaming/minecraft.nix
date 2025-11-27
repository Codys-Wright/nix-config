# Minecraft gaming aspect
{ ... }:
{
  den.aspects.minecraft = {
    description = "Minecraft with PrismLauncher";

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        prismlauncher
      ];
    };
  };
}
