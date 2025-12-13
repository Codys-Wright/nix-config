# Audio hardware facet - All audio components
{FTS, ...}: {
  FTS.hardware._.audio = {
    description = "Audio system with PipeWire and device management";
    includes = [
      FTS.hardware._.audio._.pipewire
      FTS.hardware._.audio._.wireplumber
      # Note: musnix is a function, so call it with default params
      # Users can include it directly with custom params if needed:
      # (<FTS/hardware/audio/musnix> { rtcqs = true; })
      (FTS.hardware._.audio._.musnix {})
    ];
  };
}
