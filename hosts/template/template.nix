{
  inputs,
  FTS,
  __findFile,
  ...
}:

{
  # Template host — not registered as an active host to avoid assertion failures
  # Copy this structure and rename to define a new host.

  # Template host-specific aspect
  den.aspects = {
    template = {
      # Include basic aspects for testing
      includes = [
        <FTS/fonts>
        <FTS/phoenix>

        <FTS.hardware>
        # <FTS.deployment>  # Deployment configuration (optional - uncomment when needed)
      ];

      # NixOS configuration for this host
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
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
