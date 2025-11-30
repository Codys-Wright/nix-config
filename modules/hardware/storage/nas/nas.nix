# NAS storage aspect with MergerFS support
# MergerFS sub-aspect is defined in mergerfs/mergerfs.nix
{
  FTS,
  ...
}:
{
  FTS.hardware.storage.nas = {
    description = "NAS functionality with MergerFS";
    includes = [
      FTS.hardware.storage.nas._.mergerfs
    ];
  };
}

