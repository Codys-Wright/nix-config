# Disk/filesystem configuration — type-safe parametric aspects
#
# Each filesystem type is directly callable, so a typo is a Nix attribute error
# instead of a runtime throw:
#
#   (fleet.disk.btrfs        { device = "/dev/nvme0n1"; swap = "16G"; })
#   (fleet.disk.btrfs-manual { device = "/dev/nvme0n1"; partition = 3; })
#   (fleet.disk.zfs          { rootPool = { ... }; })
#
# The old router (<fleet.system/disk> { type = "..."; }) still works for
# backwards compatibility.
{
  lib,
  fleet,
  ...
}:
{
  fleet.system._.disk.description = ''
    Disk and filesystem configuration.

    Preferred (type-safe):
      (fleet.disk.btrfs        { device = "/dev/sda"; })
      (fleet.disk.btrfs-manual { device = "/dev/nvme0n1"; partition = 3; })
      (fleet.disk.zfs          { rootPool = { ... }; })

    Legacy router (still works):
      (<fleet.system/disk> { type = "btrfs-impermanence"; device = "/dev/sda"; })
  '';

  # ── Type-safe top-level aliases ──────────────────────────────────────
  fleet.disk.description = "Disk and filesystem configuration (type-safe)";

  fleet.disk._.btrfs = fleet.system._.disk._.btrfs;
  fleet.disk._.btrfs-manual = fleet.system._.disk._.btrfs-manual;
  fleet.disk._.btrfs-partitions = fleet.system._.disk._.btrfs-partitions;
  fleet.disk._.zfs = fleet.system._.disk._.zfs;

  # ── Legacy string router (backwards compat) ─────────────────────────
  fleet.system._.disk.__functor =
    _self:
    {
      type,
      device ? null,
      swapSize ? "8",
      withSwap ? false,
      persistFolder ? "/persist",
      partition ? 3,
      bootPartition ? 1,
      subvolumes ? null,
      mountOptions ? null,
      rootPool ? null,
      dataPool ? null,
      initialBackupDataset ? true,
    }:
    { class, aspect-chain }:
    let
      types = {
        "btrfs-impermanence" = fleet.system._.disk._.btrfs {
          inherit
            device
            swapSize
            withSwap
            persistFolder
            ;
        };
        "btrfs-manual" = fleet.system._.disk._.btrfs-manual (
          {
            inherit
              device
              partition
              bootPartition
              persistFolder
              ;
          }
          // lib.optionalAttrs (subvolumes != null) { inherit subvolumes; }
          // lib.optionalAttrs (mountOptions != null) { inherit mountOptions; }
        );
        "zfs" = fleet.system._.disk._.zfs {
          inherit rootPool dataPool initialBackupDataset;
        };
      };
    in
    {
      includes = [
        (types.${type}
          or (throw "fleet.system.disk: unknown type '${type}'. Available: ${lib.concatStringsSep ", " (builtins.attrNames types)}")
        )
      ];
    };
}
