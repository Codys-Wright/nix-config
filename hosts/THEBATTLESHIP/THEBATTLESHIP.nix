{ inputs, den, pkgs, FTS, ... }:

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
        FTS.gdm
        FTS.gnome
        FTS.grub
        FTS.minegrub
        FTS.disk
        FTS.kernel  
        FTS.hardware
      ];

      # Manually set fileSystems and bootloader for now
      nixos = { config, lib, pkgs, ... }: {

        # Configure disk and filesystem
        FTS.disk = {
          enable = true;
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";  # 205GB swap for full hibernation
          persistFolder = "/persist";
        };

  # https://gist.github.com/nat-418/1101881371c9a7b419ba5f944a7118b0
      services.xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
          xfce.enable = true;
        };
      };

      programs.nh.enable = true;

      nix.settings.experimental-features = ["nix-command" "flakes"];

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
