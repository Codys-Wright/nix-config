# Music production facet.
#
# Inferno and Statime are parametric (they need per-host Dante network info),
# so they are NOT included by default here. Hosts that want Dante support
# should include them explicitly, e.g.:
#
#   (fleet.music._.production._.inferno { bindIp = "..."; deviceId = "..."; })
#   (fleet.music._.production._.statime { interface = "enp12s0"; })
{ fleet, ... }:
{
  fleet.music._.production = {
    description = "Music production tools - DAWs, plugins, Dante audio";

    includes = [
      fleet.music._.production._.axeEdit
      fleet.music._.production._.environment
      fleet.music._.production._.netaudio
      fleet.music._.production._.reaper
      fleet.music._.production._.plugins
      fleet.music._.production._.spicetify
      fleet.music._.production._.ftsRigs
    ];
  };
}
