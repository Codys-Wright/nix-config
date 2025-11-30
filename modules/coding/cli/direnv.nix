# Direnv - better than native direnv nix functionality
{
  FTS, ... }:
{
  FTS.direnv = {
    description = "Direnv for automatic environment loading";

    homeManager = { pkgs, lib, ... }: {
      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}

