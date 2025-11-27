# Example aspect subtree for demo purposes
# on a real setup you will split these over into multiple dendritic files.
{
  den,
  lib,
  ...
}:
{
  # subtree of aspects for demo purposes.
  den.aspects.example.provides = {

    # in our example, we allow all nixos hosts to be vm-bootable.
    vm-bootable = {
      nixos =
        { modulesPath, ... }:
        {
          imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
        };
    };

    # VM configuration aspect - provides fileSystems and boot loader for VMs
    vm = {
      nixos = {
        # Basic file system for VM
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        
        # Enable grub boot loader for VM
        boot.loader.grub = {
          enable = true;
          device = "/dev/vda";
        };
      };
    };

    # parametric providers.
    host =
      { host }:
      { class, ... }:
      {
        # `_` is a shorthand alias for `provides`
        includes = [ den.aspects.example._.vm-bootable ];
        ${class}.networking.hostName = host.hostName;
      };

    user =
      { user, host }:
      let
        by-class.nixos.users.users.${user.userName}.isNormalUser = true;
        by-class.darwin = {
          system.primaryUser = user.userName;
          users.users.${user.userName}.isNormalUser = true;
        };

        # adelie is nixos-on-wsl, has special additional user setup
        by-host.outrider.nixos.defaultUser = user.userName;
      in
      {
        includes = [
          by-class
          (by-host.${host.name} or { })
        ];
      };

    home =
      { home }:
      { class, ... }:
      let
        homeDir = if lib.hasSuffix "darwin" home.system then "/Users" else "/home";
      in
      {
        ${class}.home = {
          username = lib.mkDefault home.userName;
          homeDirectory = lib.mkDefault "${homeDir}/${home.userName}";
        };
        # Set stateVersion for NixOS home-manager users
        nixos.home-manager.users.${home.userName}.home.stateVersion = lib.mkDefault "25.11";
      };

  };
}

