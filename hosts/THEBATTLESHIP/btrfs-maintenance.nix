{ den, ... }:
{
  den.aspects.THEBATTLESHIP-btrfs-maintenance = {
    description = "Weekly scrub + balance for the root and Development btrfs filesystems (2026-10-21 read-only incident)";
    nixos =
      { lib, pkgs, ... }:
      let
        # 2026-10-21: / went read-only with every byte allocated to chunks
        # (1 MiB unallocated, metadata 98% full), so btrfs could not allocate
        # a metadata chunk even though `df` showed hundreds of GB free.
        # A weekly balance hands under-filled chunks back to the unallocated
        # pool before that can happen again. A low-unallocated alert
        # (< 20 GiB) runs as a Hermes cron posting to #fleet-alerts.
        balances = {
          root = {
            path = "/";
            onCalendar = "Sat *-*-* 04:00:00";
          };
          development = {
            path = "/run/media/Development";
            onCalendar = "Sat *-*-* 05:00:00";
          };
        };
        btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
      in
      {
        # `/` is already scrubbed weekly by the disk aspect; add the dev drive
        # (it is btrfs since 2026-10-20 and had no scrub).
        services.btrfs.autoScrub.fileSystems = [ "/run/media/Development" ];

        systemd.services = lib.mapAttrs' (
          name: b:
          lib.nameValuePair "btrfs-balance-${name}" {
            description = "Weekly btrfs balance of ${b.path} (return under-filled chunks to unallocated)";
            # nofail drives can be absent; skip rather than fail.
            unitConfig.ConditionPathIsMountPoint = b.path;
            serviceConfig = {
              Type = "oneshot";
              Nice = 19;
              IOSchedulingClass = "idle";
              # Empty chunks first: needs no free space, so it works even
              # when the filesystem is already fully allocated.
              ExecStartPre = "${btrfs} balance start -dusage=0 -musage=0 ${b.path}";
              ExecStart = "${btrfs} balance start -dusage=20 -musage=30 ${b.path}";
            };
          }
        ) balances;

        systemd.timers = lib.mapAttrs' (
          name: b:
          lib.nameValuePair "btrfs-balance-${name}" {
            description = "Weekly btrfs balance of ${b.path}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = b.onCalendar;
              Persistent = true;
              RandomizedDelaySec = "30min";
            };
          }
        ) balances;
      };
  };
}
