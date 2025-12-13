# Zed editor aspect with comprehensive configuration
{
  FTS, ... }:
{
  FTS.coding._.editors._.zed = {
    description = "Zed editor with comprehensive configuration and vim keybindings";

    homeManager = { config, pkgs, lib, ... }: lib.mkIf (!pkgs.stdenv.isDarwin) {
      programs.zed-editor = {
        enable = true;
      };
    };
  };
}
