# Audio hardware aspect - includes all audio components
# Sub-aspects are defined in separate files: pipewire/pipewire.nix, raysession/raysession.nix, wireguard/wireguard.nix
{
  FTS,
  ...
}:
{
  FTS.audio = {
    description = "Audio system with PipeWire and device management";
    includes = [
      FTS.pipewire
      FTS.wireguard
    ];
  };
}

