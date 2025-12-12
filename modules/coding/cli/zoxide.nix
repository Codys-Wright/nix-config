# Zoxide - smart cd
{
  FTS, ... }:
{
  FTS.coding._.cli._.zoxide = {
    description = "Zoxide smart cd replacement";

    homeManager = { pkgs, lib, ... }: {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
      };
    };
  };
}

