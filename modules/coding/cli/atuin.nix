# Atuin - shell history
{
  fleet.coding._.cli._.atuin = {
    description = "Atuin shell history manager";

    homeManager =
      { ... }:
      {
        programs.atuin = {
          enable = true;
          enableZshIntegration = true;
        };
      };
  };
}
