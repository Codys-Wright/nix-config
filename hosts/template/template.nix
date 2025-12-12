{ inputs, den, pkgs, FTS, __findFile, ... }:

{
  # Define the host
  den.hosts.x86_64-linux = {
    template = {
      description = "Template host for testing deployment";
      users.cody = { };
      aspect = "template";
    };
  };

  # Template host-specific aspect
  den.aspects = {
    template = {
      # Include basic aspects for testing
      includes = [
        <FTS.hardware>
        # <FTS.deployment>  # Deployment configuration (optional - uncomment when needed)
      ];

      # NixOS configuration for this host
      nixos = { config, lib, pkgs, ... }: {
        # Import nixos-facter-modules for hardware detection
        imports = [
          inputs.nixos-facter-modules.nixosModules.facter
        ];

        # Use facter report for hardware detection (auto-derived from hosts/template/facter.json)
        # facter.reportPath = ./facter.json;

        # deployment = {
        #   enable = true;
          
        #   ip = "192.168.1.XXX";  # Update with your actual IP address
          
        # };

      };
    };
  };
}

