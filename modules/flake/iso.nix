# Enables ISO building packages for all NixOS hosts
# Usage: nix build .#iso-dave
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      # Get all NixOS configurations for this system
      nixosConfigs = inputs.self.nixosConfigurations or { };
      
      # Filter configurations for the current system
      systemConfigs = builtins.filterAttrs
        (name: config: config.pkgs.system == system)
        nixosConfigs;
      
      # Create ISO packages for each configuration
      isoPackages = builtins.mapAttrs
        (name: config:
          # Check if isoImage is available (only if vm-bootable aspect is included)
          if config.config.system.build ? isoImage then
            config.config.system.build.isoImage
          else
            # Return a dummy package that explains the issue
            pkgs.writeTextFile {
              name = "iso-${name}-unavailable";
              text = ''
                ISO image not available for ${name}.
                Make sure the host includes the vm-bootable aspect (via example._.host).
              '';
            }
        )
        systemConfigs;
    in
    {
      packages = isoPackages;
    };
}

