# Music production facet.
#
# Inferno and Statime are parametric (they need per-host Dante network info),
# so they are NOT included by default here. Hosts that want Dante support
# should include them explicitly, e.g.:
#
#   (fleet.audio._.dante._.inferno { bindIp = "..."; deviceId = "..."; })
#   (fleet.audio._.dante._.statime { interface = "enp12s0"; })
{ fleet, ... }:
{
  # Host half: the system side of a production machine. Included by hosts.
  fleet.music._.production = {
    description = "Music production host — musnix + plugin paths, millisecond, easyeffects, fts-rigs";

    includes = [
      fleet.music._.production._.environment
      fleet.music._.production._.easyeffects
      fleet.music._.production._.millisecond
      fleet.music._.production._.ftsRigs
    ];
  };

  # User half: what a person making music needs in their home. Included by
  # the user (cody), not the host — co-op/guest accounts on a studio host
  # shouldn't receive REAPER and several GB of plugins.
  fleet.music._.production._.producer = {
    description = "Per-user music production — REAPER, plugins + plugin-dir links, guitar tooling, Axe-Edit, Spicetify";

    includes = [
      fleet.music._.production._.plugin-links
      fleet.music._.production._.plugins
      fleet.music._.production._.reaper
      fleet.music._.production._.guitar
      fleet.music._.production._.axeEdit
      fleet.music._.production._.spicetify
    ];
  };
}
