# Gamer role aspect - includes all gaming platforms
{
  den,
  FTS,
  ...
}:
{
  FTS.gamer = {
    description = "aspect for gaming configurations - includes all gaming platforms";
    includes = [
      FTS.steam
      FTS.lutris
      FTS.minecraft
      FTS.proton
    ];
  };
}

