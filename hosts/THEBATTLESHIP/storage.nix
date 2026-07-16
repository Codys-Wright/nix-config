{ den, ... }:
{
  den.aspects.THEBATTLESHIP-storage = {
    description = "Local ext4 data partitions (GAMES / AudioHaven / Development) and their permission oneshots";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # ext4 games partition
        # Keep it non-blocking so a missing/offline drive never drops the
        # machine into emergency mode during boot.
        fileSystems."/run/media/GAMES" = {
          device = "/dev/disk/by-uuid/50936b56-bf07-42eb-b345-ad21ba710525";
          fsType = "ext4";
          options = [
            "rw"
            "noauto"
            "nofail"
            "x-systemd.automount"
            "x-systemd.device-timeout=10"
            "x-systemd.idle-timeout=600"
          ];
        };

        # ext4 audio production partition
        fileSystems."/run/media/AudioHaven" = {
          device = "/dev/disk/by-uuid/a9ef263a-2ad2-4988-8f02-188061dc0228";
          fsType = "ext4";
          options = [
            "rw"
            "nofail"
          ];
        };

        # ext4 dedicated development partition (Samsung 990 EVO Plus 2TB)
        fileSystems."/run/media/Development" = {
          device = "/dev/disk/by-uuid/7e6024ba-a396-409f-92ae-27d74359240d";
          fsType = "ext4";
          options = [
            "rw"
            "nofail"
          ];
        };

        systemd.services.development-permissions = {
          description = "Ensure Development is writable by cody";
          wantedBy = [ "run-media-Development.mount" ];
          after = [ "run-media-Development.mount" ];
          bindsTo = [ "run-media-Development.mount" ];
          serviceConfig.Type = "oneshot";
          script = ''
            chown cody:users /run/media/Development
            chmod 0775 /run/media/Development
          '';
        };

        systemd.services.audiohaven-permissions = {
          description = "Ensure AudioHaven is writable by cody";
          wantedBy = [ "run-media-AudioHaven.mount" ];
          after = [ "run-media-AudioHaven.mount" ];
          bindsTo = [ "run-media-AudioHaven.mount" ];
          serviceConfig.Type = "oneshot";
          script = ''
            chown cody:users /run/media/AudioHaven
            chmod 0775 /run/media/AudioHaven
          '';
        };
      };
  };
}
