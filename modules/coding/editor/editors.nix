# Editors facet - All code editors
{
  FTS,
  ...
}:
{
  FTS.coding._.editors = {
    description = "All code editors - cursor, neovim, nvf, lazyvim, zed";
    
    includes = [
      FTS.coding._.editors._.cursor
      FTS.coding._.editors._.neovim
      FTS.coding._.editors._.nvf
      FTS.coding._.editors._.lazyvim
      FTS.coding._.editors._.zed
    ];
  };
}


