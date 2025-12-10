{ inputs, den, pkgs, FTS, deployment, ... }:

{
  # Define the host
  den.hosts.x86_64-linux = {
    example = {
      description = "example host";
      aspect = "example";
    };
  };

  # example host-specific aspect
  den.aspects = {
    example = {
      includes = [
        FTS.hardware
        deployment.default
      ];

      nixos = { config, lib, pkgs, ... }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
        # Generate hardware config with: just generate-hardware example
        # Then uncomment the line below to use it:
        # facter.reportPath = ./facter.json;

        deployment = {
          ip = "192.168.1.XXX";  # Update with your actual IP address
        };
      };
    };
  };
}
