# Gaming facet - All gaming platforms and tools
{
  FTS,
  lib,
  pkgs,
  ...
}: {
  FTS.gaming = {
    description = "All gaming platforms and tools - steam, minecraft, lutris, proton";

    includes = [
      FTS.gaming._.steam
      FTS.gaming._.minecraft
      FTS.gaming._.lutris
      FTS.gaming._.bottles
      FTS.gaming._.winboat
      FTS.gaming._.proton
      FTS.gaming._.melonloader
      FTS.gaming._.r2modman
    ];
  };
}
