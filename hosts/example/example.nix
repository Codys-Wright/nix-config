{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:
{
  # Define the host
  den.hosts.x86_64-linux = {
    example = {
      description = "example host";
      users.admin = { };  # Add users as needed
      aspect = "example";
    };
  };

  # example host-specific aspect
  den.aspects = {
    example = {
      includes = [
        # Hardware and kernel
        <FTS.hardware>
        <FTS.kernel>
        
        # Deployment (SSH, networking, secrets, VM/ISO generation)
        <FTS.deployment>
        
        # Disk configuration (uncomment and configure as needed)
        # (<FTS.system/disk> {
        #   type = "btrfs-impermanence";
        #   device = "/dev/nvme0n1";
        #   withSwap = true;
        #   swapSize = "32";
        # })
        
        # Optional: Desktop environment
        # (FTS.desktop {
        #   environment.default = "gnome";
        #   displayManager.auto = true;
        # })
      ];

      nixos = { config, lib, pkgs, ... }: {
        # Hardware detection is handled by FTS.hardware (includes FTS.hardware.facter)
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
