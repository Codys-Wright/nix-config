# Centralized SSH public keys for the fleet
# Usage: import from other modules as `ssh-keys` via _module.args
{ lib, ... }:
{
  _module.args.ssh-keys = {
    # Personal SSH public keys
    personal = {
      cody = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8y8AMfYQnvu3BvjJ54/qYJcedNkMHmnjexine1ypda cody";
      voyager = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEExJ9+wtbBN4v9uWZwZKK+K83/ZscpIyuVMCQkuMY2c cody@voyager";
    };

    # Fleet SSH public keys (deploy keys from hosts/<hostname>/ssh.pub)
    fleet = {
      THEBATTLESHIP = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGTCYWYifaiPcQVQnebV/cFVnvGULPJ2+jVEkPIEgXg THEBATTLESHIP-deploy";
      starcommand = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBJxxU1TXbV1IvGFm67X7jX+C7uRtLcgimcoDGxapNP starcommand-deploy";
    };

    # All keys as a flat list
    all = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8y8AMfYQnvu3BvjJ54/qYJcedNkMHmnjexine1ypda cody"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEExJ9+wtbBN4v9uWZwZKK+K83/ZscpIyuVMCQkuMY2c cody@voyager"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGTCYWYifaiPcQVQnebV/cFVnvGULPJ2+jVEkPIEgXg THEBATTLESHIP-deploy"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBJxxU1TXbV1IvGFm67X7jX+C7uRtLcgimcoDGxapNP starcommand-deploy"
    ];
  };
}
