# Oh My Posh prompt theme configuration
{
  FTS, ... }:
{
  FTS.oh-my-posh = {
    description = "Oh My Posh prompt theme with custom configuration";
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.oh-my-posh ];
    };

    homeManager = { pkgs, ... }: {
      programs.oh-my-posh = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
        useTheme = "catppuccin";
      };
    };
  };
}

