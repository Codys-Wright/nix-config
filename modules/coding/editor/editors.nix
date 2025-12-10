# Editors meta-aspect - includes all editor modules
{
  FTS, ... }:
{
  FTS.editors = {
    description = "All editor modules - includes code-cursor, neovim, nvf, lazyvim, astrovim, and zed";

    includes = [
      FTS.code-cursor
      FTS.nvf
      FTS.lazyvim
      FTS.zed
      # FTS.doom-btw
    ];

    nixos = { pkgs, ... }: {
      # Set nvim as the default editor at system level (testing)
      environment.sessionVariables = {
        EDITOR = "lazyvim";
        VISUAL = "lazyvim";
      };
    };

  };
}


