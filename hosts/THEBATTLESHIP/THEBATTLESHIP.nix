{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:

{

  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = { };
      users.starcommand = { };  # Service user for self-hosting infrastructure
      aspect = "THEBATTLESHIP";
      
      # Use selfhostblocks' patched nixpkgs for LLDAP and other enhanced services
      # Required by starcommand user's self-hosting stack
      instantiate = args: inputs.selfhostblocks.lib.x86_64-linux.patchedNixpkgs.nixosSystem (args // {
        system = "x86_64-linux";
      });
    };
  };

  # THEBATTLESHIP host-specific aspect that includes role-based aspects
  den.aspects = {
    THEBATTLESHIP = {
      # Include role-based aspects
      includes = [
        # System-wide theme (bootloader, default appearance)
        (<FTS.theme> { default = "cody"; })
        
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
          displayManager.auto = true;  # Auto-selects GDM for GNOME
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
        
        # Deployment configuration (SSH, networking, secrets, VM/ISO generation)
        <FTS.deployment>
        
        # Self-hosting services are provided by the starcommand user
        # See users/starcommand/starcommand.nix for service configuration
      ];

      # Manually set fileSystems and bootloader for now
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
          # The facter report path is auto-derived as hosts/THEBATTLESHIP/facter.json

          programs.nh.enable = true;

          # Self-hosting services configuration is handled by the starcommand user
          # See users/starcommand/starcommand.nix for all service configuration
        };
    };
  };

}
