# kache on voyager: its store on the dev drive with every build tree, since a
# restore is an APFS clone and cannot cross volumes. The Cargo config that
# makes kache the rustc wrapper is home-manager's
# (modules/coding/lang/kache.nix); this sets where the store is.
#
# One user builds here (CodyWright), so the store needs no group or ACL. The
# dev drive mounts with ownership ignored ("noowners") anyway: every file on
# it reads as owned by whoever looks, so nothing could be private there.
#
# NO launchd daemon, as on airlock (hosts/airlock/kache.nix): macOS TCC
# refuses a launchd job access to an external volume until someone clicks
# Allow for that binary, which every kache upgrade would ask again. kache 2
# starts its own daemon on demand from the build process instead, so it
# inherits that session's access to the drive; it exits after
# daemon_idle_timeout_secs, and with none reachable the engine works
# in-process.
#
# Disk not mounted: CodyWright cannot create /Volumes/dev-drive (root's
# /Volumes), so kache builds uncached and never writes the internal SSD.
{ ... }:
{
  den.aspects.voyager-kache = {
    description = "kache's store on voyager's dev drive";
    darwin = {
      # kache signs every S3 request and won't without keys; the Drive
      # agent's endpoint (loopback only) ignores them, so any value works.
      environment.variables = {
        KACHE_S3_ACCESS_KEY = "drive";
        KACHE_S3_SECRET_KEY = "drive";
      };

      environment.etc."kache/config.toml".text = ''
        # Misses go to the Drive agent on this computer, which asks the other
        # computers of its build group (THEBATTLESHIP + the VPS, Airlock +
        # Voyager) over Drive's peer connections: no cloud bucket
        # (FastTrackStudios/drive docs/kache.md, drive#45). No agent running:
        # the connection is refused at once and kache just compiles.
        [cache.remote]
        type = "s3"
        bucket = "kache"
        endpoint = "http://127.0.0.1:9778"
        region = "us-east-1"

        [cache]
        local_store = "/Volumes/dev-drive/.kache"
        # 3.6 TiB drive, ~2 TiB free.
        local_max_size = "300GiB"
        # Daemon features that act on target dirs: off, so nothing but cargo
        # touches a checkout's target.
        seed_new_targets = false
        auto_clean_orphaned_targets = false
        auto_share_target_files = false
        auto_clean_idle_targets_days = 0
        auto_clean_unused_units_days = 0
        # Every daemon GC (at each daemon start and every 6 h) deletes every
        # registered `-C incremental` dir; kache 2 starts a daemon whenever
        # a build finds none, so this on would wipe target/*/incremental
        # many times a day.
        clean_incremental = false
        # The on-demand daemon goes once idle.
        daemon_idle_timeout_secs = 600
      '';
    };
  };
}
