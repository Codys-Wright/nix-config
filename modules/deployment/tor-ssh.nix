# Tor SSH hidden service aspect
# Provides SSH access over Tor for privacy and NAT traversal
{
  FTS,
  lib,
  ...
}: {
  FTS.deployment._.tor-ssh = {
    description = ''
      Enable SSH access over Tor hidden service.
      
      Provides a .onion address for SSH access without port forwarding or static IP.
      Useful for accessing machines behind NAT or for privacy.
      
      Usage:
        FTS.deployment._.tor-ssh
    '';

    nixos = { config, lib, ... }: {
      services.openssh.enable = true;
      
      services.tor = {
        enable = true;
        
        relay.onionServices.hidden-ssh = {
          version = 3;
          map = [
            {
              port = 22;
              target.port = 22;
            }
          ];
        };
        
        client.enable = true;
      };
      
      # Make onion hostname readable by users
      systemd.services.tor.serviceConfig = {
        # Allow reading the onion hostname
        ReadWritePaths = [ "/var/lib/tor" ];
      };
    };
  };
}
