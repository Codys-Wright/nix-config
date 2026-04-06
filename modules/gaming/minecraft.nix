# Minecraft gaming aspect
{
  fleet,
  ...
}:
{
  fleet.gaming._.minecraft = {
    description = "Minecraft with PrismLauncher";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.prismlauncher ];
      };
  };
}
