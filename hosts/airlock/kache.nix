# kache on airlock: one store on the build disk for every Rust build here,
# rat's own (ssh, agents) and the seven GitHub runners' (studio-release-mac,
# task-release-mac, airlock), which all run as rat too. A crate one of them
# compiled is a restore for the others, as an APFS clone: the store sits on
# /Volumes/build-disk with every build tree (~/fts, the runners' work dirs,
# the canonical checkouts), since a restore cannot clone across volumes.
#
# Simpler than THEBATTLESHIP (hosts/THEBATTLESHIP/kache.nix): one user, so no
# group, no ACL, no pre-made index.db. The build disk mounts with ownership
# on and rat owns all of it.
#
# NO daemon. macOS TCC refuses a launchd job access to an external volume
# until someone clicks Allow for that job's binary on the Mac's screen (a
# probe agent got "Operation not permitted" on the build disk, 2026-10-31),
# and kache's binary is a new store path on every upgrade. The wrappers
# don't need one: they write the store themselves, and a build that finds
# the store over budget starts a detached `kache gc`. The runners and ssh
# sessions already have the volume, so the wrappers and that gc do too.
#
# Disk not mounted: /Volumes is root's, so rat cannot create
# /Volumes/build-disk/.kache, and kache builds uncached instead (it warns
# and passes through). Never run cargo as root here: root could create the
# directory on the internal SSD, and the disk would then mount as
# "build-disk 1".
{ ... }:
let
  store = "/Volumes/build-disk/.kache";
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
          # The build disk is 1.8 TiB and ~87% full. Restores are clones, so
          # the store costs extra blocks only for what no target dir holds.
          local_max_size = "120GiB"
          # Below 60 GiB free a build evicts cache entries (the studio
          # release jobs refuse to start under 50 GB). Set here because
          # kache's default is 0 in CI, and the runners are CI.
          auto_recover_min_free_bytes = 64424509440
          # Daemon features that act on target dirs: off, so nothing but
          # cargo touches the runners' warm targets or the canonical
          # checkouts' (and there is no daemon to run them anyway).
          seed_new_targets = false
          auto_clean_orphaned_targets = false
          auto_share_target_files = false
          auto_clean_idle_targets_days = 0
          auto_clean_unused_units_days = 0
          # A daemon a `kache stats` starts goes once idle.
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
        '';
        system.activationScripts.postActivation.text = lib.mkAfter ''
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
