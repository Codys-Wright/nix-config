# Audio plugins facet - effects and instruments
{FTS, ...}: {
  FTS.music._.production._.plugins = {
    description = "Audio plugins - effects and virtual instruments";

    includes = [
      FTS.music._.production._.plugins._.fx
      FTS.music._.production._.plugins._.instruments
    ];
  };
}
