# Hardware facet - All hardware support
{FTS, ...}: {
  FTS.hardware = {
    description = "All hardware support - facter, audio, bluetooth, cuda, networking, nvidia";

    includes = [
      FTS.hardware._.facter # Hardware detection using nixos-facter
      FTS.hardware._.audio
      FTS.hardware._.bluetooth
      FTS.hardware._.cuda
      FTS.hardware._.networking
      FTS.hardware._.networking._.tailscale
      FTS.hardware._.nvidia
      FTS.hardware._.storage
    ];
  };
}
