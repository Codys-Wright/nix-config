# kache on airlock: one store on the build disk for every Rust build here,
# rat's own (ssh, agents) and the seven GitHub runners' (studio-release-mac,
# task-release-mac, airlock), which all run as rat too. A crate one of them
# compiled is a restore for the others, as an APFS clone: the store sits on
# /Volumes/build-disk with every build tree (~/fts, the runners' work dirs,
# the canonical checkouts), since a restore cannot clone across volumes.
#
# Simpler than THEBATTLESHIP (hosts/THEBATTLESHIP/kache.nix): one user, so no
# group, no ACL, no pre-made index.db. The build disk mounts with ownership
# on; its root is root's, so the store goes in rat's home/ there, beside
# ~/.cargo and the runners (home/cargo, home/runner-work*).
#
# NO launchd daemon. macOS TCC refuses a launchd job access to an external
# volume until someone clicks Allow for that job's binary on the Mac's screen
# (a probe agent got "Operation not permitted" on the build disk,
# 2026-10-31), and kache's binary is a new store path on every upgrade.
# kache 2 starts its own daemon on demand instead: the first compile that
# finds none spawns `kache-engine daemon run` from the build process, so it
# inherits that runner's or ssh session's access to the volume (checked
# 2026-11-01: it opened the store's index.db and served a 28/28 restore).
# Its runtime dir (daemon.sock, daemon.log) is the store itself, one daemon
# for every rat process; it exits after daemon_idle_timeout_secs. With no
# daemon reachable the engine compiles, looks up and stores in-process.
#
# Disk not mounted: /Volumes is root's, so rat cannot create
# /Volumes/build-disk/home/kache, and kache builds uncached instead (it warns
# and passes through). Never run cargo as root here: root could create the
# directory on the internal SSD, and the disk would then mount as
# "build-disk 1".
{ ... }:
let
  store = "/Volumes/build-disk/home/kache";
  tmp = "/Volumes/build-disk/home/tmp";
in
{
  den.aspects.airlock-kache = {
    description = "kache build cache for rat and airlock's GitHub runners, its store on the build disk";
    darwin =
      { lib, pkgs, ... }:
      let
        kache = lib.getExe pkgs.kache;
      in
      {
        environment.systemPackages = [ pkgs.kache ];

        # Read by every kache process, under ~/.config/kache and KACHE_*.
        environment.etc."kache/config.toml".text = ''
          [cache]
          local_store = "${store}"
          # About 1 TB of the 1.8 TiB build disk (its old target dirs were
          # cleared 2026-11-01: kache rebuilds them in seconds). Restores
          # are clones, so the store costs extra blocks only for what no
          # target dir holds.
          local_max_size = "930GiB"
          # Below 100 GiB free a build evicts cache entries (entries only:
          # idle target dirs are auto_recover_targets, off), so the store
          # plus the build trees never fill the disk. Set here because
          # kache's default is 0 in CI, and the runners are CI.
          auto_recover_min_free_bytes = 107374182400
          # Daemon features that act on target dirs: off, so nothing but
          # cargo touches the runners' warm targets or the canonical
          # checkouts'.
          seed_new_targets = false
          auto_clean_orphaned_targets = false
          auto_share_target_files = false
          auto_clean_idle_targets_days = 0
          auto_clean_unused_units_days = 0
          # Every daemon GC (at each daemon start and every 6 h) deletes
          # every `-C incremental` dir a compile registered in the index. In
          # kache 2 every build that finds no daemon starts one, so this on
          # would wipe the runners' and checkouts' target/*/incremental
          # many times a day (the first 2.0 daemon here "cleaned 2
          # registered incremental dirs").
          clean_incremental = false
          # The on-demand daemon goes once idle.
          daemon_idle_timeout_secs = 600
        '';

        # rat has no home-manager, so the Cargo config that
        # modules/coding/lang/kache.nix writes elsewhere comes from here, and
        # is linked into rat's CARGO_HOME (~/.cargo -> the build disk). It
        # reaches every cargo rat runs, the runners' jobs included: none sets
        # its own CARGO_HOME, and Task's dev shell unsets RUSTC_WRAPPER,
        # which a Cargo config survives.
        environment.etc."kache/cargo-config.toml".text = ''
          [net]
          git-fetch-with-cli = true

          [build]
          rustc-wrapper = "${kache}"

          # Temporary files on the build disk, not in macOS's per-user
          # TMPDIR on the internal SSD (228 GB, nearly full): kache's
          # staging, rustc's and the linker's temp files. `force`, because
          # macOS always sets TMPDIR and [env] would otherwise keep it.
          [env]
          TMPDIR = { value = "${tmp}", force = true }
        '';
        system.activationScripts.postActivation.text = lib.mkAfter ''
          # kache: rat's temp dir on the build disk, for builds (see the
          # Cargo config's [env]); made only when the disk is mounted.
          if [ -d /Volumes/build-disk/home ]; then
            /usr/bin/sudo -u rat /bin/mkdir -p ${tmp}
          fi
          # kache: link rat's Cargo config (needs the build disk mounted).
          cargo_home=/Users/rat/.cargo
          if [ ! -d "$cargo_home/" ]; then
            echo "kache: $cargo_home is not reachable (build disk not mounted?); Cargo config not linked" >&2
          elif [ -e "$cargo_home/config.toml" ] && [ ! -L "$cargo_home/config.toml" ]; then
            echo "kache: $cargo_home/config.toml is a file of its own; leaving it, so cargo runs without kache" >&2
          else
            /usr/bin/sudo -u rat /bin/ln -sfn /etc/kache/cargo-config.toml "$cargo_home/config.toml"
          fi
        '';
      };
  };
}
