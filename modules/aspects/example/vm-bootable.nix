# in our example, we allow all nixos hosts to be vm-bootable.
let
  installer = variant: {
    nixos =
      { modulesPath, ... }:
      {
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-${variant}.nix") ];
      };
  };
in
{
  # Basic vm-bootable aspect
  den.aspects.example.provides.vm-bootable = {
    nixos =
      { modulesPath, ... }:
      {
        imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
      };
  };

  # make USB/VM installers with GUI/TUI variants
  den.aspects.example.provides.vm-bootable.provides = {
    tui = installer "minimal";
    gui = installer "graphical-base";
  };
}
