# Enables VM packages for NixOS hosts
# Usage: nix run .#vm-dave
# This creates runnable VMs from your NixOS configurations
# Very useful for testing configurations without rebooting
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, self', ... }:
    let
      # Get all NixOS configurations for this system
      nixosConfigs = inputs.self.nixosConfigurations or { };
      
      # Filter configurations for the current system
      systemConfigs = builtins.filterAttrs
        (name: config: config.pkgs.system == system)
        nixosConfigs;
      
      # Create VM packages for each configuration that has vm available
      vmPackages = builtins.mapAttrs
        (name: config:
          # Check if vm is available (only if virtualisation.vmVariant is enabled)
          if config.config.system.build ? vm then
            pkgs.writeShellApplication {
              name = "vm-${name}";
              text = ''
                ${config.config.system.build.vm}/bin/run-${name}-vm "$@"
              '';
            }
          else
            # Return a dummy package that explains the issue
            pkgs.writeTextFile {
              name = "vm-${name}-unavailable";
              text = ''
                VM not available for ${name}.
                Enable virtualisation.vmVariant in the host configuration to use VMs.
              '';
            }
        )
        systemConfigs;
      
      # Create a default "vm" package that runs the first available VM (or dave if it exists)
      defaultVm = 
        if systemConfigs ? dave && systemConfigs.dave.config.system.build ? vm then
          pkgs.writeShellApplication {
            name = "vm";
            text = ''
              ${systemConfigs.dave.config.system.build.vm}/bin/run-dave-vm "$@"
            '';
          }
        else
          # Find the first available VM
          let
            availableVms = builtins.filterAttrs
              (name: config: config.config.system.build ? vm)
              systemConfigs;
            firstVm = builtins.head (builtins.attrNames availableVms);
          in
          if availableVms != {} then
            pkgs.writeShellApplication {
              name = "vm";
              text = ''
                ${availableVms.${firstVm}.config.system.build.vm}/bin/run-${firstVm}-vm "$@"
              '';
            }
          else
            pkgs.writeTextFile {
              name = "vm-unavailable";
              text = ''
                No VMs available. Enable virtualisation.vmVariant in a host configuration.
              '';
            };
    in
    {
      packages = vmPackages // { vm = defaultVm; };
    };
}
