# browsers aspect
{
  FTS, ... }:
{
  FTS.hardware = {
    description = "Easily add common hardware configuration changes to your system";

    includes = [
      FTS.audio
      FTS.bluetooth
      FTS.cuda
      FTS.networking
      FTS.nvidia
    ];
  };
}

