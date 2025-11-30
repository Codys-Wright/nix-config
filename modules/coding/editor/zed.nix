# Zed editor aspect with comprehensive configuration
{
  FTS, ... }:
{
  FTS.zed = {
    description = "Zed editor with comprehensive configuration and vim keybindings";

    homeManager = { config, pkgs, lib, ... }: {
      programs.zed-editor = {
        enable = true;
      };
    };
  };
}
