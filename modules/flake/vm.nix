# Enables VM packages for NixOS hosts using nixos-generators
# Usage: nix run .#vm-dave
# Creates proper VM images with all configurations included
{ inputs, ... }:
{
  perSystem =
    { system, lib, ... }:
    let
      # Get all NixOS configurations for this system
      nixosConfigs = inputs.self.nixosConfigurations or { };

      # Filter configurations for the current system
      systemConfigs = lib.filterAttrs
        (name: config: config.pkgs.system == system)
        nixosConfigs;

      # Create VM packages using nixos-generators based on existing nixosConfigurations
      vmPackages = lib.mapAttrs'
        (name: config: lib.nameValuePair "vm-${name}"
          (inputs.nixos-generators.nixosGenerate {
            inherit system;

            # Use the same modules as the nixosConfiguration but add VM overrides
            modules = config._module.args.modules ++ [
              # VM-specific overrides for the image
              ({ config, ... }: {
                # VM services
                services.openssh.enable = true;
                services.spice-vdagentd.enable = true;
                services.qemuGuest.enable = true;

                # VM networking
                networking.hostName = "${name}-vm";

                # VM display settings
                services.xserver = {
                  enable = true;
                  videoDrivers = [ "qxl" ];
                };

                # VM-specific environment
                environment.sessionVariables = {
                  WLR_NO_HARDWARE_CURSORS = "1";
                  NIXOS_OZONE_WL = "1";
                };
              })
            ];

            format = "qcow"; # Create QEMU qcow2 image
          })
        )
        systemConfigs;
    in
    {
      packages = vmPackages;
    };
}
