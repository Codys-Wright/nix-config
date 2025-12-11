{ inputs, den, pkgs, FTS, __findFile, ... }:

{

den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = { };
      aspect = "THEBATTLESHIP";
    };
  };

  # THEBATTLESHIP host-specific aspect that includes role-based aspects
  den.aspects = {
    THEBATTLESHIP = {
      # Include role-based aspects
      includes = [
        <FTS/gdm>
        <FTS/gnome>
        (<FTS/grub> { })  # GRUB with default UEFI configuration
        <FTS/minegrub>
        # Configure disk and filesystem using function-based approach
        (<FTS/system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";  # 205GB swap for full hibernation
          persistFolder = "/persist";
        })
        <FTS/kernel>
        <FTS/hardware>
        <deployment/default>  # Deployment configuration (includes all deployment aspects)
      ];

      # Manually set fileSystems and bootloader for now
      nixos = { config, lib, pkgs, ... }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
        # The facter report path is auto-derived as hosts/THEBATTLESHIP/facter.json

  # https://gist.github.com/nat-418/1101881371c9a7b419ba5f944a7118b0
      services.xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
          xfce.enable = true;
        };
      };

      programs.nh.enable = true;

        networking.hosts = {
          "127.0.0.1" = ["n.example.com"];
        };


      
        deployment = {
          ip = "192.168.1.XXX";  # Update with your actual IP
         
        };

 
      
      };
    };
  };

}
