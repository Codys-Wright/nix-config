# Yazi - file manager
{
  FTS,
  ...
}:
{
  FTS.coding._.cli._.yazi = {
    description = "Yazi file manager";

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.yazi = {
          enable = true;
          enableZshIntegration = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
          shellWrapperName = "y";
        };
      };
  };
}
