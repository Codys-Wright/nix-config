# EXT4 filesystem configuration aspect
# Provides EXT4-specific configuration
{
  den,
  lib,
  device ? "/dev/vda",
  ...
}:
{
  den.aspects.disk.ext4 = { device ? "/dev/vda" }: {
    description = "EXT4 filesystem configuration with optional encryption support";

    nixos = {
      # Enable EXT4 support
      boot.supportedFilesystems = [ "ext4" ];

      # Disko configuration for EXT4 partitioning
      disko.devices = {
        disk = {
          disk0 = {
            type = "disk";
            device = device;
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  priority = 1;
                  name = "ESP";
                  start = "1M";
                  end = "512M";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "defaults" ];
                  };
                };
                root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                    mountOptions = [ "defaults" "relatime" ];
                  };
                };
              };
            };
          };
        };
      };

      # TODO: Add LUKS encryption support in the future
      # boot.initrd.luks.devices = { ... };
      # security.tpm2 = { ... };
    };
  };
}
