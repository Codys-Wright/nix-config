# Gaming facet - All gaming platforms and tools
{
  FTS,
  ...
}:
{
  FTS.apps._.gaming = {
    description = "All gaming platforms and tools - steam, minecraft, lutris, proton";
    
    includes = [
      FTS.apps._.gaming._.steam
      FTS.apps._.gaming._.minecraft
      FTS.apps._.gaming._.lutris
      FTS.apps._.gaming._.proton
    ];
  };
}

