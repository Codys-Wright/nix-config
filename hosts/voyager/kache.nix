# kache on voyager: its store on the dev drive with every build tree, since a
# restore is an APFS clone and cannot cross volumes. The Cargo config that
# makes kache the rustc wrapper is home-manager's
# (modules/coding/lang/kache.nix); this sets where the store is.
#
# One user builds here (CodyWright), so the store needs no group or ACL. The
# dev drive mounts with ownership ignored ("noowners") anyway: every file on
# it reads as owned by whoever looks, so nothing could be private there.
#
# NO daemon, as on airlock (hosts/airlock/kache.nix): macOS TCC refuses a
# launchd job access to an external volume until someone clicks Allow for
# that binary, which every kache upgrade would ask again. The wrappers
# write the store and start a detached `kache gc` over budget themselves.
#
# Disk not mounted: CodyWright cannot create /Volumes/dev-drive (root's
# /Volumes), so kache builds uncached and never writes the internal SSD.
{ ... }:
{
  den.aspects.voyager-kache = {
    description = "kache's store on voyager's dev drive";
    darwin = {
      environment.etc."kache/config.toml".text = ''
        [cache]
        local_store = "/Volumes/dev-drive/.kache"
        # 3.6 TiB drive, ~2 TiB free.
        local_max_size = "300GiB"
        # Daemon features that act on target dirs: off, so nothing but cargo
        # touches a checkout's target (and there is no daemon to run them).
        seed_new_targets = false
        auto_clean_orphaned_targets = false
        auto_share_target_files = false
        auto_clean_idle_targets_days = 0
        auto_clean_unused_units_days = 0
        # A daemon a `kache stats` starts goes once idle.
        daemon_idle_timeout_secs = 600
      '';
    };
  };
}
