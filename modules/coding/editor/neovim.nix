# Base Neovim configuration
# This provides the standard neovim installation that other variants can use
{
  FTS, ... }:
{
  FTS.neovim = {
    description = "Base Neovim editor configuration";

    homeManager = { pkgs, ... }: {
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;
      };

      # Set environment variables
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
  };
}

