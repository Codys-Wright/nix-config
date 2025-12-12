# Atuin - shell history
{
  FTS, ... }:
{
  FTS.coding._.cli._.atuin = {
    description = "Atuin shell history manager";

    homeManager = { pkgs, lib, ... }: {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}

