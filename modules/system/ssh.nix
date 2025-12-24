# SSH server configuration
{
  FTS,
  ...
}:
let
  # Fleet SSH public keys - allows any of our machines to SSH into any other
  # These are the deploy keys from hosts/<hostname>/ssh.pub
  fleetKeys = {
    THEBATTLESHIP = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGTCYWYifaiPcQVQnebV/cFVnvGULPJ2+jVEkPIEgXg THEBATTLESHIP-deploy";
    starcommand = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBJxxU1TXbV1IvGFm67X7jX+C7uRtLcgimcoDGxapNP starcommand-deploy";
  };

  # All fleet keys as a list
  allFleetKeys = builtins.attrValues fleetKeys;
in
{
  FTS.system._.ssh = {
    description = "SSH server configuration with secure defaults and fleet access";

    nixos = { config, lib, pkgs, ... }: {
      services.openssh = {
        enable = lib.mkDefault true;
        settings = {
          PermitRootLogin = lib.mkDefault "prohibit-password";
          PasswordAuthentication = lib.mkDefault true;
        };
        ports = [ 22 ];
      };

      # Allow all fleet machines to SSH into root
      users.users.root.openssh.authorizedKeys.keys = allFleetKeys;
    };
  };

  # Export fleet keys for use by other modules
  FTS.system._.ssh.fleetKeys = fleetKeys;
  FTS.system._.ssh.allFleetKeys = allFleetKeys;
}

