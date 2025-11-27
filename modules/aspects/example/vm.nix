{ den, ... }:
{
  # Base VM aspect - enables virtualisation.vmVariant to create system.build.vm
  den.aspects.example.provides.vm = {
    nixos = {
      virtualisation.vmVariant = {
        virtualisation = {
          memorySize = 8192; # 8GB RAM
          cores = 4;
        };
      };
    };
  };

  # VM providers for GUI and TUI variants
  den.aspects.example.provides.vm.provides = {
    gui.includes = [
      den.aspects.example._.vm
      den.aspects.example._.vm-bootable._.gui
      den.aspects.xfce-desktop
    ];

    tui.includes = [
      den.aspects.example._.vm
      den.aspects.example._.vm-bootable._.tui
    ];
  };
}
