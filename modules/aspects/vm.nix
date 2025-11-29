# VM aspect - provides virtualisation.vmVariant for VM bootable systems
# Ensures VM variant inherits host configuration with virtualization enabled
{
  den,
  lib,
  ...
}:
{
  den.aspects.vm = {
    description = "VM bootable configuration - enables virtualisation.vmVariant with inherited configuration";

    includes = [
      den.aspects.example._.vm-bootable._.gui  # GUI installer for VM compatibility
    ];

    nixos = {
      # Regular host configuration (when not in VM)
      virtualisation.vmVariant = {
        # VM-specific overrides
        virtualisation = {
          memorySize = 8192; # 8GB RAM
          cores = 4;
        };

        # Hostname for VM
        networking.hostName = "dave-vm";

        # Ensure essential services are available in VM
        services.openssh.enable = true;

        # Apply desktop environment to VM variant
        # This ensures the VM gets Hyprland with SDDM like the host
        programs.hyprland.enable = true;

        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
        };

        environment.sessionVariables = {
          WLR_NO_HARDWARE_CURSORS = "1";
          NIXOS_OZONE_WL = "1";
        };

        # Enable essential services for desktop
        services.xserver.enable = true;
        services.libinput.enable = true;

        # Set Hyprland as default session
        services.displayManager.defaultSession = "hyprland";
      };
    };
  };
}
