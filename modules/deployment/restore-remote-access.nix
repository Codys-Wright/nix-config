# Restore Remote Access aspect
# Persists SSH host keys and authorized keys across boots for consistent remote access
{
  FTS,
  lib,
  ...
}:
{
  FTS.deployment._.restore-remote-access = {
    description = ''
      Restore SSH host keys and authorized keys from initrd.

      This prevents SSH host key warnings on netboot/ephemeral systems
      by restoring persistent keys during early boot.

      Useful for:
      - Beacon installation ISOs
      - Netboot environments
      - Ephemeral systems that need consistent SSH identity

      Usage:
        FTS.deployment._.restore-remote-access
    '';

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        # Enable systemd in initrd (required for early boot services)
        boot.initrd.systemd.enable = true;

        # Restore SSH host keys and authorized keys during early boot
        boot.initrd.systemd.services.restore-state-from-initrd = {
          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = "/sysroot /dev";
          };
          wantedBy = [ "initrd.target" ];
          requiredBy = [ "rw-etc.service" ];
          before = [ "rw-etc.service" ];
          serviceConfig.Type = "oneshot";

          # Restore ssh host and user keys if they are available.
          # This avoids warnings of unknown ssh keys.
          script = ''
            mkdir -m 700 -p /sysroot/root/.ssh
            mkdir -m 755 -p /sysroot/etc/ssh
            mkdir -m 755 -p /sysroot/root/network

            # Restore authorized keys if available
            if [[ -f ssh/authorized_keys ]]; then
              install -m 400 ssh/authorized_keys /sysroot/root/.ssh
            fi

            # Restore SSH host keys
            install -m 400 ssh/ssh_host_* /sysroot/etc/ssh

            # Restore network configuration JSON files
            cp *.json /sysroot/root/network/

            # Restore machine-id for consistent system identity
            if [[ -f machine-id ]]; then
              cp machine-id /sysroot/etc/machine-id
            fi
          '';
        };
      };
  };
}
