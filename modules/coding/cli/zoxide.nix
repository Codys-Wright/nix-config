# Zoxide - smart cd
{
  fleet.coding._.cli._.zoxide = {
    description = "Zoxide smart cd replacement";

    homeManager = {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;
      };
    };
  };
}
