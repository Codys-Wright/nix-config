# Music production facet - DAWs and audio tools
{FTS, ...}: {
  FTS.music._.production = {
    description = "Music production tools - Reaper DAW, plugins, and extensions";

    includes = [
      FTS.music._.production._.environment
      FTS.music._.production._.reaper
      FTS.music._.production._.plugins
    ];
  };
}
