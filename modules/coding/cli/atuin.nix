# Atuin - shell history
{
  FTS, ... }:
{
  FTS.atuin = {
    description = "Atuin shell history manager";

    homeManager = { pkgs, lib, ... }: {
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}

