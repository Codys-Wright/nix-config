# Btrfs on specific existing partitions — dual-boot-friendly.
#
# Unlike `fleet.disk.btrfs` (which owns the whole disk, rewrites GPT, and would
# obliterate any neighboring OS) and `fleet.disk.btrfs-manual` (which doesn't
# use disko at all, so nixos-anywhere has nothing to format), this variant uses
# disko to format *only* the named partitions. Anything else on the disk
# (e.g. macOS APFS, Apple's ESP) is untouched.
#
# Usage:
#   (<fleet.disk/btrfs-partitions> {
#     rootPartlabel = "nomad-root";
#     espPartlabel  = "nomad-esp";
#   })
#
# Partitions are addressed via GPT part-label (`/dev/disk/by-partlabel/<label>`)
# so the config is immune to device-name churn (nvme0n1p3 vs sda3 etc.).
{
  inputs,
  lib,
  fleet,
  ...
}:
{
  fleet.system._.disk._.btrfs-partitions =
    {
      rootPartlabel,
      espPartlabel,
      persistFolder ? "/persist",
      subvolumes ? {
        root = "@root";
        nix = "@nix";
        persist = "@persist";
        home = "@home";
      },
      mountOptions ? [
        "compress=zstd"
        "noatime"
        "ssd"
      ],
      btrfsLabel ? "nixos",
      espLabel ? "NIXOSESP",
      withSwap ? false,
      swapSize ? "8",
    }:
    { class, aspect-chain }:
    {
      nixos =
        { pkgs, lib, ... }:
        {
          imports = [ inputs.disko.nixosModules.disko ];

          boot.supportedFilesystems = [ "btrfs" ];

          disko.devices.disk = {
            root = {
              type = "disk";
              device = "/dev/disk/by-partlabel/${rootPartlabel}";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  btrfsLabel
                ];
                subvolumes = {
                  ${subvolumes.root} = {
                    mountpoint = "/";
                    mountOptions = mountOptions;
                  };
                  ${subvolumes.nix} = {
                    mountpoint = "/nix";
                    mountOptions = mountOptions;
                  };
                  ${subvolumes.persist} = {
                    mountpoint = persistFolder;
                    mountOptions = mountOptions;
                  };
                  ${subvolumes.home} = {
                    mountpoint = "/home";
                    mountOptions = mountOptions;
                  };
                }
                // lib.optionalAttrs withSwap {
                  "@swap" = {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "${swapSize}G";
                  };
                };
              };
            };
            esp = {
              type = "disk";
              device = "/dev/disk/by-partlabel/${espPartlabel}";
              content = {
                type = "filesystem";
                format = "vfat";
                extraArgs = [
                  "-F"
                  "32"
                  "-n"
                  espLabel
                ];
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
          };

          services.btrfs.autoScrub = {
            enable = true;
            interval = "weekly";
            fileSystems = [ "/" ];
          };
        };
    };
}
