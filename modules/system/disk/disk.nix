# Disk/filesystem configuration wrapper aspect
# Provides a unified interface for different disk configuration types
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  
  description = ''
    Disk and filesystem configuration wrapper with support for different filesystem types.

    Configure via options in nixos config:
      FTS.disk = {
        enable = true;
        type = "btrfs-impermanence";
        device = "/dev/nvme2n1";
        swapSize = "205";
        withSwap = true;
        persistFolder = "/persist";
      };

    Available filesystem types: btrfs-impermanence
    More types can be added as needed.
  '';
in
{
  flake-file.inputs.disko.url = "github:nix-community/disko";
  flake-file.inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  FTS.disk = {
    inherit description;

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) mkIf mkEnableOption mkOption types;
      cfg = config.FTS.disk;
    in
    {
      # Import disko module to generate fileSystems from disko.devices
      imports = [ inputs.disko.nixosModules.disko ];

      options.FTS.disk = {
        enable = mkEnableOption "disk and filesystem configuration";

        type = mkOption {
          type = types.enum [ "btrfs-impermanence" ];
          default = "btrfs-impermanence";
          description = "Type of disk configuration to use";
        };

        device = mkOption {
          type = types.str;
          default = "/dev/vda";
          description = "Device to use for the filesystem (e.g., /dev/sda, /dev/nvme0n1)";
        };

        withSwap = mkOption {
          type = types.bool;
          default = false;
          description = "Enable swap partition";
        };

        swapSize = mkOption {
          type = types.str;
          default = "8";
          description = "Swap size in GB (without the 'G' suffix)";
        };

        persistFolder = mkOption {
          type = types.str;
          default = "/persist";
          description = "Folder to persist data for impermanence configurations";
        };
      };

      config = mkIf (cfg.enable && cfg.type == "btrfs-impermanence") {
        # Enable Btrfs support
        boot.supportedFilesystems = [ "btrfs" ];

        # Disko configuration for Btrfs partitioning with impermanence
        disko.devices = {
          disk = {
            system = {
              type = "disk";
              device = cfg.device;
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
                          mountpoint = cfg.persistFolder;
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
                        "@swap" = lib.mkIf cfg.withSwap {
                          mountpoint = "/.swapvol";
                          swap.swapfile.size = "${cfg.swapSize}G";
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
  };
}

