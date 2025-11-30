# Audio hardware aspect - includes all audio components
# Sub-aspects are defined in separate files: pipewire/pipewire.nix, raysession/raysession.nix, wireguard/wireguard.nix
{
  FTS,
  ...
}:
{
  FTS.hardware.audio = {
    description = "Audio system with PipeWire and device management";
    includes = [
      FTS.hardware.audio._.pipewire
      FTS.hardware.audio._.wireguard
    ];
  };
}

