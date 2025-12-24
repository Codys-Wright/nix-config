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
      users.guest = {}; # Minimal guest user for bootstrap
      users.starcommand = {}; # Service user for self-hosting infrastructure
      aspect = "starcommand-host"; # Use unique name to avoid conflict with user aspect

      # Use nixpkgs-unstable with selfhostblocks patches applied
      # This gives us the latest packages plus LLDAP/borgbackup enhancements
      instantiate = args: let
        system = "x86_64-linux";
        # Get pkgs from nixpkgs for applyPatches
        pkgs' = inputs.nixpkgs.legacyPackages.${system};
        # Apply selfhostblocks patches to our unstable nixpkgs
        shbPatches = inputs.selfhostblocks.lib.${system}.patches;
        patchedNixpkgs = pkgs'.applyPatches {
          name = "nixpkgs-unstable-shb-patched";
          src = inputs.nixpkgs; # Use our nixpkgs-unstable
          patches = shbPatches;
        };
        nixosSystem' = import "${patchedNixpkgs}/nixos/lib/eval-config.nix";
      in
        nixosSystem' (args // {inherit system;});
    };
  };

  # starcommand host-specific aspect (named starcommand-host to avoid conflict with user aspect)
  den.aspects = {
    starcommand-host = {
      includes = [
        # Hardware and kernel
        <FTS.hardware>
        <FTS.kernel>

        # Disk configuration with disko (for automated installation)
        (<FTS.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme0n1";
          persistFolder = "/persist";
        })

        # Deployment with deploy-rs configuration
        (<FTS.deployment> {
          ip = "192.168.0.102";
          sshPort = 22;
          sshUser = "root";
        })

        FTS.gdm

        # Self-hosting services are provided by the starcommand user
        # See users/starcommand/starcommand.nix for service configuration
      ];

      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # Bootstrap: root password and SSH keys for initial access
        users.users.root = {
          initialPassword = "password";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8y8AMfYQnvu3BvjJ54/qYJcedNkMHmnjexine1ypda cody"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBJxxU1TXbV1IvGFm67X7jX+C7uRtLcgimcoDGxapNP starcommand-deploy"
          ];
        };

        # GRUB bootloader (UEFI)
        # Use efiInstallAsRemovable to install to fallback location (/boot/EFI/BOOT/BOOTX64.EFI)
        # This ensures GRUB is used instead of any previous bootloader (systemd-boot)
        boot.loader.grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          efiInstallAsRemovable = true;
          configurationLimit = 25;
        };
        boot.loader.efi.canTouchEfiVariables = false;

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
          device = "/dev/sdc2";
          fsType = "ntfs-3g";
          options = ["rw" "uid=0" "gid=0" "dmask=000" "fmask=000" "nofail"];
        };

        # MergerFS mount combining all disks
        fileSystems."/mnt/storage" = {
          device = "/mnt/disks/sda:/mnt/disks/sdc";
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
