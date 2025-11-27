{ ... }:
{
  # Base VM aspect - enables virtualisation.vmVariant to create system.build.vm
  vm.vm = {
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
  vm.vm.provides = {
    gui.includes = [
      vm.vm
      vm.vm-bootable._.gui
      vm.xfce-desktop
    ];

    tui.includes = [
      vm.vm
      vm.vm-bootable._.tui
    ];
  };
}
