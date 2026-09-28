# Audio hardware facet. PipeWire and musnix take per-host settings
# (settings.hardware.audio.{pipewire,musnix}.*) rather than call arguments.
{ fleet, ... }:
{
  fleet.hardware._.audio = {
    description = "Audio system (PipeWire + musnix realtime)";
    includes = [
      fleet.hardware._.audio._.pipewire
      fleet.hardware._.audio._.musnix
      fleet.raysession
    ];
  };
}
