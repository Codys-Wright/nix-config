# Fish shell aspect with custom configuration
{
  FTS, ... }:
{
  FTS.fish = {
    description = "Fish shell with custom configuration and optimizations";

    homeManager = { config, pkgs, lib, ... }: {
      programs.fish = {
        enable = true;
      };

    };
  };
}
