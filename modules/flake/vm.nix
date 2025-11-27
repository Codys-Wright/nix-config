# Enables VM packages for NixOS hosts
# Usage: nix run .#vm-dave
# It is very useful to have a VM you can edit your config and launch the VM to test stuff
# instead of having to reboot each time.
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, lib, ... }:
    let
      # Get all NixOS configurations for this system
      nixosConfigs = inputs.self.nixosConfigurations or { };
      
      # Filter configurations for the current system
      systemConfigs = lib.filterAttrs
        (name: config: config.pkgs.system == system)
        nixosConfigs;
      
      # Create VM packages for each configuration that has vm available
      # Package keys are prefixed with "vm-" so they can be run as: nix run .#vm-dave
      vmPackages = lib.mapAttrs
        (name: config:
          # Check if vm is available (only if virtualisation.vmVariant is enabled)
          if config.config.system.build ? vm then
            pkgs.writeShellApplication {
              name = "vm-${name}";
              text = ''
                ${config.config.system.build.vm}/bin/run-nixos-vm "$@"
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
      
      # Prefix package keys with "vm-" for easier access
      prefixedPackages = lib.mapAttrs'
        (name: pkg: lib.nameValuePair "vm-${name}" pkg)
        vmPackages;
    in
    {
      packages = prefixedPackages;
    };
}
