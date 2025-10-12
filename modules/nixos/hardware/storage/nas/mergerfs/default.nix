{ config, lib, namespace, pkgs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.storage.nas.mergerfs;
in
{
  options.${namespace}.hardware.storage.nas.mergerfs = with types; {
    enable = mkBoolOpt false "Enable MergerFS functionality";
  };

  config = mkIf cfg.enable {
    # NAS configuration will go here
    environment.systemPackages = with pkgs; [
      mergerfs
      ntfs3g
    ];

    # Mount individual disks
    fileSystems."/mnt/disks/sda" = {
      device = "/dev/sda2";
      fsType = "ntfs-3g";
      options = ["rw" "uid=0" "gid=993" "umask=0007" "nofail"];  # Mount as root:selfhost
    };

    fileSystems."/mnt/disks/sdb" = {
      device = "/dev/sdb2";
      fsType = "ntfs-3g";
      options = ["rw" "uid=0" "gid=993" "umask=0007" "nofail"];  # Mount as root:selfhost
    };

    # MergerFS mount combining all disks
    fileSystems."/mnt/storage" = {
      fsType = "fuse.mergerfs";
      device = "/mnt/disks/*";
      options = ["cache.files=partial" "dropcacheonclose=true" "category.create=mfs" "allow_other" "nofail"];
    };
  };
}