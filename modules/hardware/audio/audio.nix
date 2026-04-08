# Audio hardware facet - All audio components
{ fleet, ... }:
{
  fleet.hardware._.audio = {
    description = "Audio system with PipeWire and device management";
    includes = [
      fleet.hardware._.audio._.pipewire
      fleet.hardware._.audio._.wireplumber
      # Note: musnix is a function, so call it with default params
      # Users can include it directly with custom params if needed:
      # (<fleet/hardware/audio/musnix> { rtcqs = true; })
      (fleet.hardware._.audio._.musnix { })
      fleet.raysession
    ];
  };
}
