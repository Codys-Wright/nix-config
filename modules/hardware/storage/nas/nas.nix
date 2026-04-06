# NAS storage aspect with MergerFS support
# MergerFS sub-aspect is defined in mergerfs/mergerfs.nix
{
  fleet,
  ...
}:
{
  fleet.hardware._.storage._.nas = {
    description = "NAS functionality with MergerFS";
    includes = [
      fleet.hardware._.storage._.nas._.mergerfs
    ];
  };
}
