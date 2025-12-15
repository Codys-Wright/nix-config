# Base Neovim configuration
# This provides the standard neovim installation that other variants can use
{FTS, ...}: {
  FTS.coding._.editors._.neovim = {
    description = "Base Neovim editor configuration";

    homeManager = {pkgs, ...}: {
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = false;
      };

      # Set environment variables
      home.sessionVariables = {
        EDITOR = "lazyvim";
        VISUAL = "lazyvim";
      };
    };
  };
}
