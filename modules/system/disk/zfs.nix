# ZFS disk configuration aspect
# Takes named parameters for root pool and data pool configuration
{
  inputs,
  lib,
  FTS,
  ...
}:
{
  # Function that produces a ZFS disk configuration aspect
  # Takes named parameters: { rootPool, dataPool, initialBackupDataset, ... }
  # Usage: (<FTS/system/disk/zfs> { rootPool = {...}; })
  FTS.system._.disk._.zfs =
    {
      rootPool,
      dataPool ? null,
      initialBackupDataset ? true,
      ...
    }@args:
    { class, aspect-chain }:
    let
      inherit (lib) mkIf optionals optionalString optionalAttrs;
      hasRaid = rootPool.disk2 != null;
      dataPoolEnabled = dataPool != null && (dataPool.enable or true);
      
      mkRoot = { disk, id ? "" }: {
        type = "disk";
        device = disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot${id}";
                # Otherwise you get https://discourse.nixos.org/t/security-warning-when-installing-nixos-23-11/37636/2
                mountOptions = [ "umask=0077" ];
                # Copy the host_key needed for initrd in a location accessible on boot.
                # It's prefixed by /mnt because we're installing and everything is mounted under /mnt.
                # We're using the same host key because, well, it's the same host!
                postMountHook = ''
                  cp /tmp/host_key /mnt/boot${id}/host_key
                '';
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = rootPool.name;
              };
            };
          };
        };
      };

      mkDataDisk = dataDisk: {
        type = "disk";
        device = dataDisk;
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = dataPool.name;
              };
            };
          };
        };
      };
    in
    {
      description = "ZFS disk configuration with root pool and optional data pool";

      nixos = { pkgs, lib, ... }:
        {
          # Import disko module to generate fileSystems from disko.devices
          imports = [ inputs.disko.nixosModules.disko ];

          disko.devices = {
            disk = {
              root = mkRoot { disk = rootPool.disk1; };
              # Second root must have id=-backup.
              root1 = mkIf hasRaid (mkRoot { disk = rootPool.disk2; id = "-backup"; });
              data1 = mkIf dataPoolEnabled (mkDataDisk dataPool.disk1);
              data2 = mkIf dataPoolEnabled (mkDataDisk dataPool.disk2);
            };

            zpool = {
              ${rootPool.name} = {
                type = "zpool";
                mode = if hasRaid then "mirror" else "";
                options = {
                  ashift = "12";
                  autotrim = "on";
                };
                rootFsOptions = {
                  encryption = "on";
                  keyformat = "passphrase";
                  keylocation = "file:///tmp/root_passphrase";
                  compression = "lz4";
                  canmount = "off";
                  xattr = "sa";
                  atime = "off";
                  acltype = "posixacl";
                  recordsize = "1M";
                  "com.sun:auto-snapshot" = "false";
                };
                # Need to use another variable name otherwise I get SC2030 and SC2031 errors.
                preCreateHook = ''
                  pname=$name
                '';
                # Needed to get back a prompt on next boot.
                # See https://github.com/nix-community/nixos-anywhere/issues/161#issuecomment-1642158475
                postCreateHook = ''
                  zfs set keylocation="prompt" $pname
                '';
                # Follows https://grahamc.com/blog/erase-your-darlings/
                datasets = {
                  # TODO: compute percentage automatically in postCreateHook
                  "reserved" = {
                    options = {
                      canmount = "off";
                      mountpoint = "none";
                      # TODO: compute this value using percentage
                      reservation = rootPool.reservation;
                    };
                    type = "zfs_fs";
                  };
                  "local/root" = {
                    type = "zfs_fs";
                    mountpoint = "/";
                    options.mountpoint = "legacy";
                    postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^${rootPool.name}/local/root@blank$' || zfs snapshot ${rootPool.name}/local/root@blank";
                  };
                  "local/nix" = {
                    type = "zfs_fs";
                    mountpoint = "/nix";
                    options.mountpoint = "legacy";
                  };
                  "safe/home" = {
                    type = "zfs_fs";
                    mountpoint = "/home";
                    options.mountpoint = "legacy";
                  };
                  "safe/persist" = {
                    type = "zfs_fs";
                    mountpoint = "/persist";
                    # It's prefixed by /mnt because we're installing and everything is mounted under /mnt.
                    options.mountpoint = "legacy";
                    postMountHook = optionalString dataPoolEnabled ''
                      cp /tmp/data_passphrase /mnt/persist/data_passphrase
                    '';
                  };
                };
              };

              ${dataPool.name} = mkIf dataPoolEnabled {
                type = "zpool";
                mode = "mirror";
                options = {
                  ashift = "12";
                  autotrim = "on";
                };
                rootFsOptions = {
                  encryption = "on";
                  keyformat = "passphrase";
                  keylocation = "file:///tmp/data_passphrase";
                  compression = "lz4";
                  canmount = "off";
                  xattr = "sa";
                  atime = "off";
                  acltype = "posixacl";
                  recordsize = "1M";
                  "com.sun:auto-snapshot" = "false";
                  mountpoint = "none";
                };
                # Need to use another variable name otherwise I get SC2030 and SC2031 errors.
                preCreateHook = ''
                  pname=$name
                '';
                postCreateHook = ''
                  zfs set keylocation="file:///persist/data_passphrase" $pname;
                '';
                datasets = {
                  # TODO: create reserved dataset automatically in postCreateHook
                  "reserved" = {
                    options = {
                      canmount = "off";
                      mountpoint = "none";
                      # TODO: compute this value using percentage
                      reservation = dataPool.reservation;
                    };
                    type = "zfs_fs";
                  };
                } // optionalAttrs initialBackupDataset {
                  "backup" = {
                    type = "zfs_fs";
                    mountpoint = "/srv/backup";
                    options.mountpoint = "legacy";
                  };
                  # TODO: create datasets automatically upon service installation (e.g. Nextcloud, etc.)
                  #"nextcloud" = {
                  #  type = "zfs_fs";
                  #  mountpoint = "/srv/nextcloud";
                  #};
                };
              };
            };
          };

          # File systems configuration
          fileSystems = {
            "/boot".neededForBoot = true;
            "/boot-backup" = mkIf hasRaid { neededForBoot = true; };
            "/srv/backup" = mkIf (dataPoolEnabled && initialBackupDataset) {
              options = [ "nofail" ];
            };
          };

          # ZFS boot configuration
          boot = {
            supportedFilesystems = [ "zfs" ];
            zfs = {
              forceImportRoot = false;
              # To import the zpool automatically
              extraPools = optionals dataPoolEnabled [ dataPool.name ];
            };
          };

          # Follows https://grahamc.com/blog/erase-your-darlings/
          # https://github.com/NixOS/nixpkgs/pull/346247/files
          boot.initrd.postResumeCommands = lib.mkAfter ''
            zfs rollback -r ${rootPool.name}/local/root@blank
          '';

          services.zfs.autoScrub.enable = true;
        };
    };
}

