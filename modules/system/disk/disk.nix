# Disk/filesystem configuration wrapper aspect
# Provides a unified interface for different disk configuration types
{
  FTS,
  ...
}:
{
  # Create disk as a provider under FTS.system with description
  FTS.system._.disk.description = ''
    Disk and filesystem configuration with support for different filesystem types.
    
    Usage as router:
      (<FTS/system/disk> { type = "btrfs-impermanence"; device = "/dev/sda"; })
      (<FTS/system/disk> { type = "btrfs-manual"; device = "/dev/nvme0n1"; partition = 3; })
    
    Direct access to specific types:
      (<FTS/system/disk/btrfs> { device = "/dev/sda"; })
      (<FTS/system/disk/btrfs-manual> { device = "/dev/nvme0n1"; partition = 3; })
      (<FTS/system/disk/zfs> { rootPool = {...}; })
  '';

  # Make disk callable as a router function
  FTS.system._.disk.__functor =
    _self:
    {
      type,
      # Btrfs parameters (shared)
      device ? null,
      swapSize ? "8",
      withSwap ? false,
      persistFolder ? "/persist",
      # Btrfs-manual specific parameters
      partition ? 3,
      bootPartition ? 1,
      subvolumes ? null,
      mountOptions ? null,
      # ZFS parameters
      rootPool ? null,
      dataPool ? null,
      initialBackupDataset ? true,
      ...
    }@args:
    { class, aspect-chain }:
    {
      includes = [
        # Route to the appropriate disk type implementation
        (if type == "btrfs-impermanence" then
          (FTS.system._.disk._.btrfs {
            inherit device swapSize withSwap persistFolder;
          })
        else if type == "btrfs-manual" then
          (FTS.system._.disk._.btrfs-manual ({
            inherit device partition bootPartition persistFolder;
          } // (if subvolumes != null then { inherit subvolumes; } else {})
            // (if mountOptions != null then { inherit mountOptions; } else {})))
        else if type == "zfs" then
          (FTS.system._.disk._.zfs {
            inherit rootPool dataPool initialBackupDataset;
          })
        else
          throw "FTS.system.disk: unsupported type '${type}'. Available types: btrfs-impermanence, btrfs-manual, zfs")
      ];
    };
}

