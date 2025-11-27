# Gamer role aspect - includes all gaming platforms
{
  den,
  ...
}:
{
  den.aspects.gamer = {
    description = "aspect for gaming configurations - includes all gaming platforms";
    includes = [
      den.aspects.steam
      den.aspects.lutris
      den.aspects.minecraft
      den.aspects.proton
    ];
  };
}

