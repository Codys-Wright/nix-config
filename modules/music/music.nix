# Music facet - All music-related tools
{ fleet, ... }:
{
  fleet.music = {
    description = "Music production and audio tools";

    includes = [
      fleet.music._.production
    ];
  };
}
