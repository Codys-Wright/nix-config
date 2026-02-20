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
        <FTS/fonts>
        <FTS/phoenix>

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

        # MergerFS, NTFS, and SMB packages
        environment.systemPackages = with pkgs; [
          mergerfs
          ntfs3g
          cifs-utils
        ];

        # Data drives (NTFS via ntfs-3g) - full read/write access for everyone
        # Using UUIDs instead of device names to handle device name changes
        # sdb2: "THE ARCHIVE" - 10.9TB
        fileSystems."/mnt/disks/archive" = {
          device = "/dev/disk/by-uuid/36C0F5ACC0F5730B";
          fsType = "ntfs-3g";
          options = ["rw" "uid=0" "gid=0" "dmask=000" "fmask=000" "nofail"];
        };
        # sdc2: "THE COLLECTION" - 10.9TB
        fileSystems."/mnt/disks/collection" = {
          device = "/dev/disk/by-uuid/02A01CC8A01CC3D7";
          fsType = "ntfs-3g";
          options = ["rw" "uid=0" "gid=0" "dmask=000" "fmask=000" "nofail"];
        };

        # MergerFS mount combining all disks
        fileSystems."/mnt/storage" = {
          device = "/mnt/disks/archive:/mnt/disks/collection";
          fsType = "fuse.mergerfs";
          options = [
            "cache.files=partial"
            "dropcacheonclose=true"
            "category.create=mfs"
            "allow_other"
            "nofail"
          ];
        };

        # SMB mount to Synology NAS "TheVault"
        # Using IP address since NetBIOS name resolution failed
        # vers=1.0 required for older Synology DSM versions
        fileSystems."/mnt/synology-vault" = {
          device = "//192.168.0.114/Media";  # Using IP address
          fsType = "cifs";
          options = [
            "username=soundaddiction"
            "password=C#major7"  # Corrected password
            "vers=1.0"  # Required for older Synology NAS
            "uid=0"
            "gid=0"
            "dir_mode=0755"
            "file_mode=0644"
            "nofail"
            "x-systemd.automount"
            "x-systemd.mount-timeout=10"
          ];
        };

        # Create service data directories on merged storage
        # These directories will hold user content (media, torrents, photos, etc.)
        # NOTE: NTFS mounted with uid=0 gid=0 (root) and 777 permissions (world-writable)
        # Services can read/write but files appear owned by root
        systemd.tmpfiles.rules = [
          "d /mnt/storage/torrents 0777 root root -" # Deluge downloads
          "d /mnt/storage/youtube 0777 root root -" # YouTube downloads
          "d /mnt/storage/photos 0777 root root -" # Immich photo library
          "d /mnt/storage/nextcloud-data 0777 root root -" # Nextcloud External Storage
          "d /mnt/storage/media 0777 root root -" # Jellyfin media libraries
          "d /mnt/storage/media/movies 0777 root root -"
          "d /mnt/storage/media/tv 0777 root root -"
          "d /mnt/storage/media/music 0777 root root -"
          "d /mnt/storage/media/audiobooks 0777 root root -"
          # SMB credentials directory
          "d /etc/smb-credentials 0750 root root -"
        ];

        # Automatic cleanup
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        programs.nh.enable = true;

        # Disable all sleep/suspend/hibernate for this server
        systemd.sleep.extraConfig = ''
          AllowSuspend=no
          AllowHibernation=no
          AllowSuspendThenHibernate=no
          AllowHybridSleep=no
        '';

        # Prevent power button from suspending
        services.logind = {
          powerKey = "ignore";
          powerKeyLongPress = "poweroff";
          lidSwitch = "ignore";
          lidSwitchDocked = "ignore";
          lidSwitchExternalPower = "ignore";
        };
      };
    };
  };
}
