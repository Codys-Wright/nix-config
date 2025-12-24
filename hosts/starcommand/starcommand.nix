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

        # Disk configuration (btrfs with impermanence)
        (<FTS.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme0n1";
          withSwap = true;
          swapSize = "32"; # 32GB swap
          persistFolder = "/persist";
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
        # Automatic cleanup
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        # Limit boot generations
        boot.loader.grub.configurationLimit = 5;

        programs.nh.enable = true;
      };
    };
  };
}
