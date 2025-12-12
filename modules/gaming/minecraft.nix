# Minecraft gaming aspect
{
  FTS,
  ...
}:
{
  FTS.apps._.gaming._.minecraft = {
    description = "Minecraft with PrismLauncher";

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.prismlauncher ];
    };

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = [ pkgs.prismlauncher ];
    };
  };
}
