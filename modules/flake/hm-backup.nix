{
  den.aspects.hm-backup = {
    nixos.home-manager.backupFileExtension = "hm-backup";
    # Use extension-based backup for Darwin (simpler and more reliable)
    # If a backup already exists, it will be overwritten (user should clean up old backups)
    darwin.home-manager.backupFileExtension = "hm-backup";
  };
}
