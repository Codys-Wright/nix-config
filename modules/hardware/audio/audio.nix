# Audio hardware facet.
#
# Default instance of the PipeWire sub-aspect with no overrides — hosts that
# need special defaults (default sink, sticky HDMI nodes, etc.) should include
# `(fleet.hardware._.audio._.pipewire { ... })` themselves, which replaces
# this default via den's parametric-dispatch rules.
{ fleet, ... }:
{
  fleet.hardware._.audio = {
    description = "Audio system (PipeWire + musnix realtime)";
    includes = [
      (fleet.hardware._.audio._.pipewire { })
      (fleet.hardware._.audio._.musnix { })
      fleet.raysession
    ];
  };
}
