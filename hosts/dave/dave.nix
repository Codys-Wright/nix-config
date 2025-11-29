{ inputs, den, ... }:

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
        den.aspects.developer
        den.aspects.vm  # Enable VM bootable support
        den._.user  # Configure users defined in den.hosts.*.users.*
        den.aspects.carter._.password  # Set password for carter user
        (den.aspects.system { hostname = "dave"; timezone = "America/New_York"; locale = "en_US.UTF-8"; })
        (den.aspects.disk {
          type = "btrfs";
          impermanence = true;
          encrypted = false;
          swapsize = "4G";
          device = "/dev/vda";
        })
        (den.aspects.desktop {
          environment = "hyprland";
          display-manager = { type = "sddm"; theme = "minecraft"; };
          bootloader = { type = "grub"; theme = "minecraft-double-menu"; };
        })  # All desktop environments with hyprland as default, minecraft-themed SDDM, and minecraft GRUB
        (den.aspects.terminals { default = "ghostty"; })  # All terminal modules with ghostty as default
        (den.aspects.browsers { default = "brave"; })  # All browser modules with brave as default
        (den.aspects.shell { default = "fish"; })  # All shell modules with fish as default
        (den._.unfree true)  # Allow unfree packages (add more package names as needed)
      ];
    };
  };

}

