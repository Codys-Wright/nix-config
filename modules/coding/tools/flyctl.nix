# Fly.io CLI - deploy apps to Fly
{ fleet, ... }:
{
  fleet.coding._.tools._.flyctl = {
    description = "flyctl - Fly.io command-line deploy tool";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.flyctl ];
      };
  };
}
