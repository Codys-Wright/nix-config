{ inputs, den, pkgs, FTS, ... }:

{

den.hosts.x86_64-linux = {
    dave = {
      description = "Dave system configuration";
      users.carter = { };
      aspect = "dave";
    };
  };

  # dave host-specific aspect that includes role-based aspects
  den.aspects = {
    dave = {
      # Include role-based aspects
      includes = [
        FTS.developer
        den._.vm  # Enable VM bootable support
        den._.iso  # Enable ISO image generation
        den._.user  # Configure users defined in den.hosts.*.users.*
        FTS.carter._.password  # Set password for carter user
        FTS.example._.autologin  # Enable autologin for display manager
        (FTS.system { hostname = "dave"; timezone = "America/New_York"; locale = "en_US.UTF-8"; })
        (FTS.disk {
          type = "btrfs";
          impermanence = true;
          encrypted = false;
          swapsize = "4G";
          device = "/dev/vda";
        })

        FTS.sddm
        FTS.kde
        FTS.minegrub
        # (FTS.desktop {
        #   environment = "hyprland";
        #   display-manager = { type = "sddm"; theme = "minecraft"; };
        #   bootloader = { type = "grub"; theme = "minecraft-double-menu"; };
        # })  # All desktop environments with hyprland as default, minecraft-themed SDDM, and minecraft GRUB
        (FTS.terminals { default = "ghostty"; })  # All terminal modules with ghostty as default
        (FTS.browsers { default = "brave"; })  # All browser modules with brave as default
        (FTS.shell { default = "fish"; })  # All shell modules with fish as default
        (den._.unfree true)  # Allow unfree packages (add more package names as needed)
        FTS.package-test  # Test packages: cowsay, hello, vim
      ];

      # Manually set fileSystems and bootloader for now
      nixos = { config, lib, pkgs, ... }: {
        # File systems - using /dev/vda partitions for VM
        # /dev/vda1 = ESP (boot) partition
        # /dev/vda2 = root partition with btrfs subvolumes
      
        # Default user configuration
        users.users.carter = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" ];
          initialPassword = "password";
          description = "Default user";
        };

        # Enable sudo for wheel group
        security.sudo.wheelNeedsPassword = false;

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
  #         user = "carter";
  #       };
  #     };


      environment.systemPackages = with pkgs; [
        neovim
      ];
      
      };
    };
  };

}

