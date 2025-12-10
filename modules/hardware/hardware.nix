# browsers aspect
{
  FTS, ... }:
{
  FTS.hardware = {
    description = "Easily add common hardware configuration changes to your system";

    includes = [
      FTS.facter  # Hardware detection using nixos-facter
      FTS.audio
      FTS.bluetooth
      FTS.cuda
      FTS.networking
      FTS.nvidia
    ];
  };
}

