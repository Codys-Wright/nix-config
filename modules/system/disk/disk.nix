# Disk/filesystem configuration — type-safe parametric aspects
#
# Each filesystem type is directly callable, so a typo is a Nix attribute error
# instead of a runtime throw:
#
#   (fleet.disk.btrfs        { device = "/dev/nvme0n1"; swap = "16G"; })
#   (fleet.disk.btrfs-manual { device = "/dev/nvme0n1"; partition = 3; })
#   (fleet.disk.zfs          { rootPool = { ... }; })
#
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
  '';

  # ── Type-safe top-level aliases ──────────────────────────────────────
  fleet.disk.description = "Disk and filesystem configuration (type-safe)";

  fleet.disk._.btrfs = fleet.system._.disk._.btrfs;
  fleet.disk._.btrfs-manual = fleet.system._.disk._.btrfs-manual;
  fleet.disk._.btrfs-partitions = fleet.system._.disk._.btrfs-partitions;
  fleet.disk._.zfs = fleet.system._.disk._.zfs;
}
