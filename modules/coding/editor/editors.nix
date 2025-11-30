# Editors meta-aspect - includes all editor modules
{
  FTS, ... }:
{
  FTS.editors = {
    description = "All editor modules - includes code-cursor, neovim, nvf, lazyvim, astrovim, and zed";

    includes = [
      FTS.code-cursor
      FTS.neovim
      FTS.nvf
      FTS.lazyvim
      FTS.astrovim
      FTS.zed
      # FTS.doom-btw
    ];
  };
}

