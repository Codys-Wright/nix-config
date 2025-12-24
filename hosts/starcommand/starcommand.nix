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
      users.starcommand = {}; # Service user for self-hosting infrastructure
      aspect = "starcommand";

      # Use nixpkgs-unstable with selfhostblocks patches applied
      instantiate = args: let
        system = "x86_64-linux";
        pkgs' = inputs.nixpkgs.legacyPackages.${system};
        shbPatches = inputs.selfhostblocks.lib.${system}.patches;
        patchedNixpkgs = pkgs'.applyPatches {
          name = "nixpkgs-unstable-shb-patched";
          src = inputs.nixpkgs;
          patches = shbPatches;
        };
        nixosSystem' = import "${patchedNixpkgs}/nixos/lib/eval-config.nix";
      in
        nixosSystem' (args // {inherit system;});
    };
  };

  # starcommand host-specific aspect
  den.aspects = {
    starcommand = {
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

        # Deployment (SSH, networking, secrets, VM/ISO generation)
        <FTS.deployment>

        # Self-hosting services are provided by the starcommand user
        # See users/starcommand/starcommand.nix for service configuration
      ];

      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # Deploy-rs configuration
        deployment.ip = "192.168.0.102";
        deployment.sshPort = 22;
        deployment.sshUser = "admin";

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
