# Btrfs-impermanence disk configuration aspect
# Takes named parameters: device, swapSize, withSwap, persistFolder
{
  inputs,
  lib,
  FTS,
  ...
}:
{
  # Function that produces a btrfs-impermanence disk configuration aspect
  # Takes named parameters: { device, swapSize, withSwap, persistFolder, ... }
  # Usage: (<FTS/system/disk/btrfs> { device = "/dev/sda"; })
  FTS.system._.disk._.btrfs =
    {
      device,
      swapSize ? "8",
      withSwap ? false,
      persistFolder ? "/persist",
      ...
    }@args:
    { class, aspect-chain }:
    {
      flake-file.inputs.disko.url = "github:nix-community/disko";
      flake-file.inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

      nixos = { pkgs, lib, ... }:
        {
          # Import disko module to generate fileSystems from disko.devices
          imports = [ inputs.disko.nixosModules.disko ];

          # Enable Btrfs support
          boot.supportedFilesystems = [ "btrfs" ];

          # Disko configuration for Btrfs partitioning with impermanence
          disko.devices = {
            disk = {
              system = {
                type = "disk";
                device = device;
                content = {
                  type = "gpt";
                  partitions = {
                    ESP = {
                      priority = 1;
                      name = "ESP";
                      start = "1M";
                      end = "512M";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "defaults" ];
                      };
                    };
                    bios = {
                      name = "BIOS";
                      size = "1M";
                      type = "EF02";
                    };
                    root = {
                      size = "100%";
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-f" ]; # Override existing partition
                        # Subvolumes must set a mountpoint in order to be mounted,
                        # unless their parent is mounted
                        subvolumes = {
                          "@root" = {
                            mountpoint = "/";
                            mountOptions = [
                              "compress=zstd"
                              "noatime"
                            ];
                          };
                          "@persist" = {
                            mountpoint = persistFolder;
                            mountOptions = [
                              "compress=zstd"
                              "noatime"
                            ];
                          };
                          "@nix" = {
                            mountpoint = "/nix";
                            mountOptions = [
                              "compress=zstd"
                              "noatime"
                            ];
                          };
                          "@swap" = lib.mkIf withSwap {
                            mountpoint = "/.swapvol";
                            swap.swapfile.size = "${swapSize}G";
                          };
                        };
                      };
                    };
                  };
                };
              };
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

