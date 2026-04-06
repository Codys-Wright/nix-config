# Music production facet - DAWs and audio tools
{ fleet, ... }:
{
  fleet.music._.production = {
    description = "Music production tools - Reaper DAW, plugins, and extensions";

    includes = [
      fleet.music._.production._.axeEdit
      fleet.music._.production._.environment
      fleet.music._.production._.reaper
      fleet.music._.production._.plugins
    ];
  };
}
