# Storage hardware aspect
{
  FTS,
  ...
}:
{
  FTS.hardware._.storage = {
    description = "Automatic storage mounting support";

    nixos = { ... }: {
      # Enable automatic mounting of external and internal hard drives
      services.udisks2 = {
        enable = true;
        settings = {
          "udisks2.conf" = {
            defaults = {
              mount_options = "uid=1000,gid=100,umask=0007";
              filesystem = "ntfs-3g";
            };
          };
        };
      };
      
      # Configure polkit rules for udisks2 to allow mounting without authentication
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (
            subject.isInGroup("users")
              && (
                action.id == "org.freedesktop.udisks2.filesystem-mount" ||
                action.id == "org.freedesktop.udisks2.filesystem-unmount" ||
                action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
                action.id == "org.freedesktop.udisks2.filesystem-unmount-system" ||
                action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
                action.id == "org.freedesktop.udisks2.encrypted-unlock-system" ||
                action.id == "org.freedesktop.udisks2.loop-setup" ||
                action.id == "org.freedesktop.udisks2.loop-delete" ||
                action.id == "org.freedesktop.udisks2.loop-modify" ||
                action.id == "org.freedesktop.udisks2.loop-setup-system" ||
                action.id == "org.freedesktop.udisks2.loop-delete-system" ||
                action.id == "org.freedesktop.udisks2.loop-modify-system" ||
                action.id == "org.freedesktop.udisks2.drive-eject" ||
                action.id == "org.freedesktop.udisks2.drive-detach" ||
                action.id == "org.freedesktop.udisks2.drive-detach-system" ||
                action.id == "org.freedesktop.udisks2.drive-set-spindown" ||
                action.id == "org.freedesktop.udisks2.drive-set-spindown-system"
              )
          ) {
            return polkit.Result.YES;
          }
        })
      '';
      
      services.gvfs.enable = true;
      services.devmon.enable = true;
    };
  };
}

