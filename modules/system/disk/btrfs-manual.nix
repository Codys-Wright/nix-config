# Manual btrfs configuration aspect for existing btrfs setups
# Does NOT use disko - just defines fileSystems for an existing layout
# Takes named parameters: device, partition, subvolumes, bootPartition, persistFolder
{
  inputs,
  lib,
  FTS,
  ...
}:
{
  # Function that produces a manual btrfs disk configuration aspect
  # Usage: (<FTS/system/disk/btrfs-manual> {
  #   device = "/dev/nvme0n1";
  #   partition = 3;  # /dev/nvme0n1p3
  #   bootPartition = 1;  # /dev/nvme0n1p1
  #   persistFolder = "/persist";
  #   subvolumes = {
  #     root = "@root";
  #     nix = "@nix";
  #     persist = "@persist";
  #   };
  # })
  FTS.system._.disk._.btrfs-manual =
    {
      device,
      partition ? 3,
      bootPartition ? 1,
      persistFolder ? "/persist",
      subvolumes ? {
        root = "@root";
        nix = "@nix";
        persist = "@persist";
      },
      mountOptions ? [
        "noatime"
        "compress=zstd:3"
        "ssd"
        "discard=async"
        "space_cache=v2"
      ],
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Build partition path from device
      partitionPath =
        if lib.hasInfix "nvme" device then
          "${device}p${toString partition}"
        else
          "${device}${toString partition}";
      bootPath =
        if lib.hasInfix "nvme" device then
          "${device}p${toString bootPartition}"
        else
          "${device}${toString bootPartition}";
    in
    {
      nixos = { pkgs, lib, ... }:
        {
          # Enable Btrfs support
          boot.supportedFilesystems = [ "btrfs" ];

          # Manual fileSystems configuration for existing btrfs
          fileSystems = {
            "/" = {
              device = partitionPath;
              fsType = "btrfs";
              options = [ "subvol=${subvolumes.root}" ] ++ mountOptions;
            };

            "/nix" = {
              device = partitionPath;
              fsType = "btrfs";
              options = [ "subvol=${subvolumes.nix}" ] ++ mountOptions;
            };

            # Make /nix/store read-only
            "/nix/store" = {
              device = partitionPath;
              fsType = "btrfs";
              options = [ "subvol=${subvolumes.nix}" "ro" "nosuid" "nodev" ] ++ mountOptions;
            };

            "${persistFolder}" = {
              device = partitionPath;
              fsType = "btrfs";
              neededForBoot = true;
              options = [ "subvol=${subvolumes.persist}" ] ++ mountOptions;
            };

            "/boot" = {
              device = bootPath;
              fsType = "vfat";
            };
          };

          # Btrfs maintenance services
          services.btrfs.autoScrub = {
            enable = true;
            interval = "weekly";
            fileSystems = [ "/" ];
          };
        };
    };
}
