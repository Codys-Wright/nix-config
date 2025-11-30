# MergerFS sub-aspect (can be included independently)
{
  FTS,
  ...
}:
{
  FTS.hardware.storage.nas._.mergerfs = {
    description = "MergerFS functionality for combining multiple disks";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        mergerfs
        ntfs3g
      ];

      # Mount individual disks
      fileSystems."/mnt/disks/sda" = {
        device = "/dev/sda2";
        fsType = "ntfs-3g";
        options = ["rw" "uid=1000" "gid=100" "umask=0007" "nofail"];
      };

      fileSystems."/mnt/disks/sdb" = {
        device = "/dev/sdb2";
        fsType = "ntfs-3g";
        options = ["rw" "uid=1000" "gid=100" "umask=0007" "nofail"];
      };

      # MergerFS mount combining all disks
      fileSystems."/mnt/storage" = {
        fsType = "fuse.mergerfs";
        device = "/mnt/disks/*";
        options = ["cache.files=partial" "dropcacheonclose=true" "category.create=mfs" "nofail"];
      };
    };
  };
}

