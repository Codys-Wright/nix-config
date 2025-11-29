# Btrfs filesystem configuration aspect
# Provides Btrfs-specific configuration including auto-scrub and impermanence support
{ inputs, den, lib, FTS, swapSize ? "4G", device ? "/dev/vda", ... }:
{
  flake-file.inputs.disko.url = "github:nix-community/disko";
  flake-file.inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  FTS.disk.btrfs = { swapSize ? "4G", encrypted ? false, device ? "/dev/vda" }: {
    description = "Btrfs filesystem configuration with auto-scrub, impermanence, and optional encryption support";

    nixos = { config, lib, ... }: {
      # Import disko module to generate fileSystems from disko.devices
      imports = [ inputs.disko.nixosModules.disko ];

      # Enable Btrfs support
      boot.supportedFilesystems = [ "btrfs" ];

      # Disko configuration for Btrfs partitioning
      disko.devices = {
        disk = {
          disk0 = {
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
                      "@nix" = {
                        mountpoint = "/nix";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@swap" = {
                        mountpoint = "/.swapvol";
                        swap.swapfile.size = swapSize;
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

      # Impermanence support for Btrfs
      boot.initrd.postDeviceCommands = lib.mkBefore ''
        mkdir -p /mnt
        mount -o subvol=/ /dev/disk/by-label/nixos /mnt

        # Create snapshot if it doesn't exist
        if ! btrfs subvolume show /mnt/root-blank >/dev/null 2>&1; then
          btrfs subvolume snapshot /mnt/@root /mnt/root-blank 2>/dev/null || true
        fi

        # Delete and recreate root subvolume for impermanence
        btrfs subvolume delete /mnt/@root 2>/dev/null || true
        btrfs subvolume snapshot /mnt/root-blank /mnt/@root 2>/dev/null || true
      '';

      # TODO: Add LUKS encryption support in the future
      # boot.initrd.luks.devices = { ... };
      # security.tpm2 = { ... };
    };
  };
}
