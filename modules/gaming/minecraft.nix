# Minecraft gaming aspect
{
  FTS,
  ...
}:
{
  FTS.gaming._.minecraft = {
    description = "Minecraft with PrismLauncher";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.prismlauncher ];
      };
  };
}
