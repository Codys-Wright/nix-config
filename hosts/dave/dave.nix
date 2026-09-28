{ __findFile, ... }:
{
  # QEMU/terraform test VM with an XFCE desktop (disk layout: /dev/vda).
  den.hosts.x86_64-linux.dave = {
    description = "Dave system configuration";
    users.cody = { };
  };

  den.aspects.dave = {
    includes = [
      <fleet/fonts>
      <fleet/phoenix>
      <fleet/kernel>
      <fleet/hardware>
    ];

    nixos = {
      # /dev/vda for the QEMU virtual disk (change for bare metal):
      # vda1 = ESP, vda2 = root.
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

      security.sudo.wheelNeedsPassword = false;

      # Remote access for terraform-driven setup. Password auth and root login
      # are for initial provisioning; restrict once keys are in place.
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
        settings.PermitRootLogin = "yes";
        openFirewall = true;
      };

      # https://gist.github.com/nat-418/1101881371c9a7b419ba5f944a7118b0
      services.xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
          xfce.enable = true;
        };
      };
    };
  };
}
