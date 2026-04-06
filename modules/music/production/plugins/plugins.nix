# Audio plugins facet - effects and instruments
{ fleet, ... }:
{
  fleet.music._.production._.plugins = {
    description = "Audio plugins - effects and virtual instruments";

    includes = [
      fleet.music._.production._.plugins._.fx
      fleet.music._.production._.plugins._.instruments
    ];
  };
}
