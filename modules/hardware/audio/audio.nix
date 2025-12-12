# Audio hardware facet - All audio components
{
  FTS,
  ...
}:
{
  FTS.hardware._.audio = {
    description = "Audio system with PipeWire and device management";
    includes = [
      FTS.hardware._.audio._.pipewire
      FTS.hardware._.audio._.wireplumber
    ];
  };
}

