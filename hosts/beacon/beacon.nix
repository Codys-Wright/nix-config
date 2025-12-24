{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}:
{
  # Generic beacon ISO for installing any host
  den.hosts.x86_64-linux.beacon = {
    description = "Universal installation beacon ISO";
    aspect = "beacon-aspect";
    # Don't include default home-manager for ISO
    includes = [ ];
  };

  # Beacon aspect - bootable installation ISO
  den.aspects.beacon-aspect = {
    description = "Universal bootable installation beacon";

    includes = [
      # Include deployment configuration for beacon
      (FTS.deployment {
        ip = "192.168.0.100"; # Default beacon IP (can be overridden by DHCP)
        sshPort = 22;
        sshUser = "installer";
      })

      # Include the beacon module with hardcoded trusted SSH keys
      FTS.deployment._.beacon

      # Include beacon display (QR code + connection info)
      FTS.deployment._.beacon-display

      # Include WiFi support (iwd)
      FTS.deployment._.wifi
    ];

    nixos =
      {
        modulesPath,
        pkgs,
        lib,
        ...
      }:
      {
        # Import the minimal installation CD module
        imports = [
          (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
        ];

        # Override hostname
        networking.hostName = lib.mkForce "nixos-beacon";

        # Ensure nixos-facter and installation tools are available
        environment.systemPackages = with pkgs; [
          nixos-facter
          git
          vim
          tmux
        ];
      };
  };
}
