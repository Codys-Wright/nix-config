{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}: {
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = {};
      users.starcommand = {}; # Service user for self-hosting infrastructure
      aspect = "THEBATTLESHIP";

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

  # THEBATTLESHIP host-specific aspect that includes role-based aspects
  den.aspects = {
    THEBATTLESHIP = {
      # Include role-based aspects
      includes = [
        # System-wide theme (bootloader, default appearance)
        (<FTS.theme> {default = "cody";})

        # Complete desktop setup (environment + display manager + bootloader)
        (FTS.desktop {
          environment.default = "gnome";
          bootloader = {
            default = "grub";
            grub = {
              uefi = true;
              # theme is set by system theme preset
            };
          };
          displayManager.auto = true; # Auto-selects GDM for GNOME
        })

        # Disk and filesystem configuration
        (<FTS.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205"; # 205GB swap for full hibernation
          persistFolder = "/persist";
        })

        # Hardware and kernel
        <FTS.kernel>
        <FTS.hardware>
        <FTS.keyboard>

        # Deployment configuration (SSH, networking, secrets, VM/ISO generation)
        <FTS.deployment>

        # Self-hosting services are provided by the starcommand user
        # See users/starcommand/starcommand.nix for service configuration
      ];

      # Manually set fileSystems and bootloader for now
      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
        # The facter report path is auto-derived as hosts/THEBATTLESHIP/facter.json

        # Note: Overlays for stable/unstable package access are already configured
        # globally in modules/nix/nix.nix. The base nixpkgs is already unstable
        # with selfhostblocks patches applied via the instantiate function above.
        # You can access stable packages via pkgs.stable and unstable via pkgs.unstable.

        # Limit number of generations in boot partition (critical with 512MB boot)
        boot.loader.grub.configurationLimit = 2; # Only keep last 2 generations in GRUB

        # Automatic cleanup
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };

        programs.nh.enable = true;

        fileSystems."run/media/GAMES" = {
          device = "/dev/nvme2n1p2";
          fsType = "ntfs-3g";
          options = ["rw" "uid=1000"];
        };

        # Self-hosting services configuration is handled by the starcommand user
        # See users/starcommand/starcommand.nix for all service configuration
      };
    };
  };
}
