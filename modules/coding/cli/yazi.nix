# Yazi - file manager
{
  FTS, ... }:
{
  FTS.yazi = {
    description = "Yazi file manager";

    homeManager = { pkgs, lib, ... }: {
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        shellWrapperName = "y";
      };
    };
  };
}

