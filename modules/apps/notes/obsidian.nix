# Atuin - shell history
{
  FTS, ... }:
{
  FTS.obsidian = {
    description = "Obsidian notes vault";

    homeManager = { pkgs, lib, ... }: {
      programs.obsidian.enable = true;
    };
  };
}

