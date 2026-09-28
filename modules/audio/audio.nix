# Audio. One tree for the whole stack:
#
#   <fleet/audio>              PipeWire — every machine with sound (via <fleet/hardware>)
#   <fleet.audio/studio>       real-time production host: musnix + RaySession
#                              (+ opt-in rt-isolation, see rt-isolation.nix)
#   <fleet.audio/dante>        Dante AoIP tooling: netaudio + inferno-control;
#                              hosts also call (fleet.audio._.dante._.statime { … })
#                              and (fleet.audio._.dante._.inferno { … }) with
#                              their own network details.
#
# Per-host PipeWire/musnix knobs are aspect settings: settings.audio.{pipewire,musnix}.*
# DAWs, plugins and the per-user producer half live in modules/music/production.
{ fleet, ... }:
{
  fleet.audio = {
    description = "Audio system (PipeWire)";
    includes = [ fleet.audio._.pipewire ];
  };

  fleet.audio._.studio = {
    description = "Real-time audio production host — musnix RT tuning + RaySession";
    includes = [
      fleet.audio._.musnix
      fleet.audio._.raysession
    ];
  };
}
