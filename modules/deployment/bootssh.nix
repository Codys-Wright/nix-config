# Boot SSH module
# Enables SSH access during initrd boot for remote unlocking
{
  inputs,
  den,
  lib,
  deployment,
  ...
}:
{
  deployment.bootssh = {
    description = "SSH access during initrd boot for remote system access";

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) mkOption optionals types;
      cfg = config.deployment.boot;
    in
    {
      options.deployment.boot = {
        sshPort = mkOption {
          type = types.int;
          description = "Port the SSH daemon used during initrd boot listens to";
          default = 2223;
        };

        hostKeys = mkOption {
          type = types.listOf types.str;
          description = "List of host key paths for SSH during initrd";
          default = [];
        };

        authorizedKeys = mkOption {
          type = types.listOf types.str;
          description = "Public SSH keys authorized for initrd SSH access";
          default = [];
        };
      };

      config = {
        # Enables DHCP in stage-1 even if networking.useDHCP is false
        boot.initrd.network.udhcpc.enable = lib.mkDefault (config.deployment.staticNetwork == null);

        # Enable SSH during initrd boot
        boot.initrd.network = {
          # This will use udhcp to get an ip address. Nixos-facter should have found the correct drivers
          # to load but in case not, they need to be added to `boot.initrd.availableKernelModules`.
          # Static ip addresses might be configured using the ip argument in kernel command line:
          # https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt
          enable = true;
          ssh = {
            enable = true;
            # To prevent ssh clients from freaking out because a different host key is used,
            # a different port for ssh is used.
            port = lib.mkDefault cfg.sshPort;
            hostKeys = lib.mkForce cfg.hostKeys;
            # Public ssh key used for login.
            # This should contain just one line and removing the trailing
            # newline could be fixed with a removeSuffix call but treating
            # it as a file containing multiple lines makes this forward compatible.
            authorizedKeys = cfg.authorizedKeys;
          };
        };

        boot.kernelParams = lib.optionals (config.deployment.staticNetwork != null && (config.facter.report or {}) != {}) (let
          cfg' = config.deployment.staticNetwork;
          # Use hostname from config (set by den) or fallback to a default
          hostname = config.networking.hostName or "nixos";
        in [
          # https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt
          # ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>:<dns0-ip>:<dns1-ip>:<ntp0-ip>
          "ip=${cfg'.ip}::${cfg'.gateway}:255.255.255.0:${hostname}-initrd:${cfg'.deviceName}:off:::"
        ]);
      };
    };
  };
}

