# Yazi - file manager
{
  fleet.coding._.cli._.yazi = {
    description = "Yazi file manager";

    homeManager = {
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
