# Zsh shell aspect with custom configuration
{
  FTS, ... }:
{
  FTS.coding._.shells._.zsh = {
    description = "Zsh shell with custom configuration and optimizations";

    homeManager = { config, pkgs, lib, ... }: {
      programs.zsh = {
        enable = true;
      };
    };
  };
}
