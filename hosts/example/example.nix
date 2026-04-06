{
  fleet,
  __findFile,
  ...
}:
{
  # Template host — not registered as an active host to avoid assertion failures
  # Copy this aspect to define a new host:
  #
  # den.hosts.x86_64-linux = {
  #   myhostname = {
  #     description = "my host";
  #     users.admin = { };
  #     aspect = "myhostname";
  #   };
  # };

  # example host-specific aspect
  den.aspects = {
    example = {
      includes = [
        <fleet/fonts>
        <fleet/phoenix>

        # Hardware and kernel
        <fleet.hardware>
        <fleet.kernel>

        # Deployment (SSH, networking, secrets, VM/ISO generation)
        (<fleet.deployment> { })

        # Disk configuration (uncomment and configure as needed)
        # (<fleet.system/disk> {
        #   type = "btrfs-impermanence";
        #   device = "/dev/nvme0n1";
        #   withSwap = true;
        #   swapSize = "32";
        # })

        # Optional: Desktop environment
        # (fleet.desktop {
        #   environment.default = "gnome";
        #   displayManager.auto = true;
        # })
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          # Hardware detection is handled by fleet.hardware (includes fleet.hardware.facter)
          # Generate hardware config with: just generate-hardware example
          # The facter report path is auto-derived as hosts/example/facter.json

          # Optional: Configure static network
          # deployment.staticNetwork = {
          #   ip = "192.168.1.XXX";
          #   gateway = "192.168.1.1";
          #   device = "en*";
          # };

          # Optional: Enable boot SSH for remote unlocking (if encrypted disk)
          # Requires: hosts/example/initrd_ssh_host_key
          # deployment.bootssh.enable = true;

          # Optional: Enable WiFi hotspot for bootstrap
          # deployment.hotspot.enable = true;
        };
    };
  };
}
