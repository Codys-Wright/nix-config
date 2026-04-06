# Direnv - better than native direnv nix functionality
{
  fleet.coding._.cli._.direnv = {
    description = "Direnv for automatic environment loading";

    homeManager = {
      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
