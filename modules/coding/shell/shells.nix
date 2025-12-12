# Shells facet - All shell environments
{
  FTS,
  ...
}:
{
  FTS.coding._.shells = {
    description = "All shell environments - fish, zsh, nushell, oh-my-posh";
    
    includes = [
      FTS.coding._.shells._.fish
      FTS.coding._.shells._.zsh
      FTS.coding._.shells._.nushell
      FTS.coding._.shells._.oh-my-posh
    ];
  };
}

