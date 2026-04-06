# Universal installation beacon aspect
# Bundles everything needed for a bootable NixOS installer ISO.
# Includes WiFi, QR code display, SSH keys, and nixos-anywhere support.
#
# Usage in a host file:
#   den.hosts.x86_64-linux.beacon = {
#     aspect = "my-beacon";
#     includes = [];  # skip home-manager defaults for ISO
#   };
#   den.aspects.my-beacon.includes = [ FTS.beacon ];
{
  FTS,
  ...
}:
{
  FTS.beacon = {
    description = "Universal bootable installation beacon ISO with QR code display and WiFi";

    includes = [
      FTS.deployment._.beacon
      FTS.deployment._.beacon-display
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
        imports = [
          (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
        ];

        networking.hostName = lib.mkForce "nixos-beacon";

        environment.systemPackages = with pkgs; [
          nixos-facter
          git
          vim
          tmux
        ];
      };
  };
}
