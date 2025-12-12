# NAS storage aspect with MergerFS support
# MergerFS sub-aspect is defined in mergerfs/mergerfs.nix
{
  FTS,
  ...
}:
{
  FTS.hardware._.storage._.nas = {
    description = "NAS functionality with MergerFS";
    includes = [
      FTS.hardware._.storage._.nas._.mergerfs
    ];
  };
}

