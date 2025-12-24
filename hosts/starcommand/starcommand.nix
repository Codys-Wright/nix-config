{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}: {
  den.hosts.x86_64-linux = {
    starcommand = {
      description = "Dedicated selfhosting server";
      users.guest = {}; # Minimal guest user for bootstrap (no secrets required)
      # users.starcommand = {}; # Service user for self-hosting infrastructure (add back after bootstrap)
      aspect = "starcommand-host"; # Use unique name to avoid conflict with user aspect
    };
  };

  # starcommand host-specific aspect (named starcommand-host to avoid conflict with user aspect)
  den.aspects = {
    starcommand-host = {
      includes = [
        # Hardware and kernel
        <FTS.hardware>
        <FTS.kernel>

        # Disk configuration - existing btrfs layout (no reformatting)
        (<FTS.system/disk> {
          type = "btrfs-manual";
          device = "/dev/nvme0n1";
          partition = 3; # nvme0n1p3 has the btrfs
          bootPartition = 1; # nvme0n1p1 is EFI
          persistFolder = "/persist";
          subvolumes = {
            root = "@root";
            nix = "@nix";
            persist = "@persist";
          };
        })

        # Deployment with deploy-rs configuration
        (<FTS.deployment> {
          ip = "192.168.0.102";
          sshPort = 22;
          sshUser = "root";
        })

        # Self-hosting services are provided by the starcommand user
        # See users/starcommand/starcommand.nix for service configuration
      ];

      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # GRUB bootloader (UEFI)
        boot.loader.grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          configurationLimit = 10;
        };
        boot.loader.efi.canTouchEfiVariables = true;

        # MergerFS and NTFS packages
        environment.systemPackages = with pkgs; [
          mergerfs
          ntfs3g
        ];

        # Data drives (NTFS via ntfs-3g) - full read/write access for everyone
        fileSystems."/mnt/disks/sda" = {
          device = "/dev/sda2";
          fsType = "ntfs-3g";
          options = ["rw" "uid=0" "gid=0" "dmask=000" "fmask=000" "nofail"];
        };
        fileSystems."/mnt/disks/sdb" = {
          device = "/dev/sdb2";
          fsType = "ntfs-3g";
          options = ["rw" "uid=0" "gid=0" "dmask=000" "fmask=000" "nofail"];
        };

        # MergerFS mount combining all disks
        fileSystems."/mnt/storage" = {
          device = "/mnt/disks/sda:/mnt/disks/sdb";
          fsType = "fuse.mergerfs";
          options = [
            "cache.files=partial"
            "dropcacheonclose=true"
            "category.create=mfs"
            "allow_other"
            "nofail"
          ];
        };

        # Automatic cleanup
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        programs.nh.enable = true;
      };
    };
  };
}
