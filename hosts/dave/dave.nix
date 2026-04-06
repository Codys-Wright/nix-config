{
  inputs,
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    dave = {
      description = "Dave system configuration";
      # users.carter = { };
      users.cody = { };
      aspect = "dave";
    };
  };

  # dave host-specific aspect that includes role-based aspects
  den.aspects = {
    dave = {
      # Include role-based aspects
      includes = [
        <fleet/fonts>
        <fleet/phoenix>

        # Complete desktop setup with GNOME

        <fleet.kernel>
        <fleet.hardware>
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
          # File systems - using /dev/vda partitions for VM
          # /dev/vda1 = ESP (boot) partition
          # /dev/vda2 = root partition with btrfs subvolumes

          # User configuration is now provided by den.aspects.cody.provides.hostUser
          # No need to define it here - it's automatically applied when users.cody = { } is set

          # Filesystem — /dev/vda for QEMU virtual disk (can be changed for bare metal)
          fileSystems."/" = {
            device = "/dev/vda2";
            fsType = "ext4";
          };
          fileSystems."/boot" = {
            device = "/dev/vda1";
            fsType = "vfat";
          };
          boot.loader.grub = {
            enable = true;
            device = "/dev/vda";
          };

          # Enable sudo for wheel group
          security.sudo.wheelNeedsPassword = false;

          # Enable SSH for remote access (needed for terraform)
          services.openssh = {
            enable = true;
            # Allow password authentication for initial setup
            # Consider disabling this and using keys only in production
            settings.PasswordAuthentication = true;
            # Allow root login for terraform (can be restricted later)
            settings.PermitRootLogin = "yes";
            # Open firewall port for SSH
            openFirewall = true;
          };

          # NetworkManager (enabled by fleet.gnome) will automatically handle DHCP
          # No need to configure useDHCP - NetworkManager manages networking

          # https://gist.github.com/nat-418/1101881371c9a7b419ba5f944a7118b0
          services.xserver = {
            enable = true;
            desktopManager = {
              xterm.enable = false;
              xfce.enable = true;
            };
          };

          #     services.displayManager = {
          #       defaultSession = lib.mkDefault "xfce";
          #       enable = true;
          #       autoLogin = {
          #         enable = true;
          #         user = "cody";
          #       };
          #     };
        };
    };
  };
}
