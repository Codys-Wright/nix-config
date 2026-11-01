# One kache store for every Rust build on THEBATTLESHIP: cody's (cargo, dx,
# agents) and the 14 FastTrackStudios runners' (user github-runner). A crate
# one of them compiled is a restore for the others, as a reflink: the store
# sits on the Development drive with every build tree, since a restore
# cannot cross a mount. starcommand-ci (the deploy runner) is not in the
# group and never sees the store.
#
# NOT one daemon for everyone: kache (1.x and 2.x) cannot serve another
# user. Its daemon binds the socket 0600 inside a 0700 directory it must own
# (kunobi-daemon `unix_socket::ensure_private_dir` / `bind_private`), and
# drops every connection, on the main socket and the control socket alike,
# whose SO_PEERCRED uid is not its own (src/transport.rs
# `require_self_peer`, called from daemon.rs
# `handle_connection_after_queue` and daemon_control.rs). Nothing turns
# that off. So:
#
#   - The STORE is shared: group `kache`, setgid, with a default ACL so every
#     file and directory a member creates is group read/write whatever its
#     umask (the runners run with UMask=0066). Every user's processes write
#     the store as themselves.
#   - index.db is made here, 0660: SQLite creates it 0644, which a default
#     ACL turns into group read-only, and every other user's store then
#     fails with "attempt to write a readonly database" (the build still
#     passes, uncached). SQLite gives its -wal/-shm the database's mode.
#   - A daemon per runtime dir. kache 2 (still uid-locked, kache-ipc
#     `require_self_peer`) starts one on the first compile that finds none
#     (src/main.rs `run_wrapper_mode`), so cody, agent and each runner get
#     their own, on demand, gone after daemon_idle_timeout_secs. Upstream
#     supports exactly this: many daemons on one store, each with its own
#     KACHE_RUNTIME_DIR (docs/remote-cache/ci.mdx); GC takes the store's GC
#     lock, so two daemons never sweep at once. Where a client cannot hand
#     its compile to the daemon (the runners: NoNewPrivileges, a syscall
#     filter), it compiles and stores in-process.
#   - The system daemon below (user kache, never idle) keeps the store's GC
#     and index upkeep going when no one builds; nothing connects to it.
#   - The target-dir features (seeding, orphan and unit cleaning, file
#     sharing) read target_roots from the shared index, so a daemon of one
#     user would act on, or fail on, the others' target dirs. They are off
#     in the host config for every daemon.
#   - Each user keeps its runtime dir (logs, its own socket) out of the
#     store: a daemon chmods its socket's directory 0700, and the runtime
#     dir defaults to the store.
{ ... }:
let
  store = "/run/media/Development/.kache";
  # Who builds into the store: cody, the FastTrackStudios runners, and
  # `agent` (Paperclip's builds).
  members = [
    "cody"
    "github-runner"
    "agent"
  ];
in
{
  den.aspects.THEBATTLESHIP-kache = {
    description = "One kache store for cody and the FastTrackStudios runners, kept by a system kache daemon";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        kache = lib.getExe pkgs.kache;
        # The FastTrackStudios runners (user github-runner), not
        # github-starcommand (user starcommand-ci).
        runners = lib.filterAttrs (
          _: r: r.enable && r.user == "github-runner"
        ) config.services.github-runners;
      in
      lib.mkMerge [
        {
          users.users.kache = {
            isSystemUser = true;
            group = "kache";
            description = "kache shared build cache";
            home = "/var/lib/kache";
          };
          users.groups.kache.members = members;

          # Read by every kache process (merged under ~/.config/kache and the
          # KACHE_* environment, which win).
          environment.etc."kache/config.toml".text = ''
            [cache]
            local_store = "${store}"
            local_max_size = "400GiB"
            # Per user, never the store (the runners and the daemon set
            # KACHE_RUNTIME_DIR instead; a runner's home is read-only to it).
            runtime_dir = "~/.cache/kache"
            # Target dirs are per user; the index that lists them is shared.
            seed_new_targets = false
            auto_clean_orphaned_targets = false
            auto_share_target_files = false
            auto_clean_idle_targets_days = 0
            auto_clean_unused_units_days = 0
            auto_recover_min_free_bytes = 0
            # Every daemon GC (at each daemon start and every 6 h) deletes
            # every `-C incremental` dir a compile registered in the shared
            # index; a user's own daemon (kache 2) can, and would wipe
            # cody's target/*/incremental many times a day.
            clean_incremental = false
            # A daemon a `kache` command starts for its user goes once idle.
            daemon_idle_timeout_secs = 600
          '';

          # `agent` has no home-manager, so it gets cody's Cargo config
          # (modules/coding/lang/kache.nix) from here: every cargo it runs —
          # Paperclip's builds, gate-queue — goes through kache.
          environment.etc."kache/cargo-config.toml".text = ''
            [net]
            git-fetch-with-cli = true

            [build]
            rustc-wrapper = "${lib.getExe pkgs.kache}"
          '';
          # A private OUT_DIR alias root per user. kache compiles some
          # registry proc macros (paste, linkme-impl, …) against an empty
          # read-only OUT_DIR under this root, so the path they bake in is
          # the same in every checkout; without it each checkout bakes its
          # own target/ path and everything downstream misses. The root must
          # be owned by the building user and writable by no one else
          # (src/out_dir_alias.rs `root_is_safe`), so the default
          # <store>/out-dirs (cody's, created first) serves cody only; agent
          # and the runners get their own. Crates downstream of an aliased
          # macro therefore key per user.
          environment.etc."kache/agent-config.toml".text = ''
            [cache]
            out_dir_alias_root = "${store}/out-dirs-agent"
          '';

          systemd.tmpfiles.rules = [
            "d /home/agent/.cargo 0755 agent users -"
            "L+ /home/agent/.cargo/config.toml - - - - /etc/kache/cargo-config.toml"
            "d /home/agent/.config/kache 0755 agent users -"
            "L+ /home/agent/.config/kache/config.toml - - - - /etc/kache/agent-config.toml"
          ];

          # The store's directory, its ACL and index.db, once the drive is
          # mounted (tmpfiles refuses a kache-owned path under the cody-owned
          # mount). A store from before it was shared is moved aside.
          systemd.services.kache-store = {
            description = "Prepare the shared kache store on the Development drive";
            wantedBy = [ "run-media-Development.mount" ];
            after = [ "run-media-Development.mount" ];
            bindsTo = [ "run-media-Development.mount" ];
            path = [
              pkgs.acl
              pkgs.coreutils
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              store=${store}
              if [ -e "$store" ] && [ "$(stat -c %U "$store")" != kache ]; then
                rm -rf "$store.pre-shared"
                mv "$store" "$store.pre-shared"
              fi
              install -d -m 2770 -o kache -g kache "$store"
              setfacl -b "$store"
              setfacl -m g:kache:rwx,d:u::rwx,d:g::rwx,d:g:kache:rwx,d:m::rwx,d:o::--- "$store"
              [ -e "$store/index.db" ] || install -m 0660 -o kache -g kache /dev/null "$store/index.db"
            '';
          };

          systemd.services.kache = {
            description = "kache daemon for the shared store (GC, index upkeep)";
            wantedBy = [ "multi-user.target" ];
            bindsTo = [ "kache-store.service" ];
            after = [ "kache-store.service" ];
            environment = {
              KACHE_RUNTIME_DIR = "/run/kache";
              KACHE_DAEMON_IDLE_TIMEOUT = "0";
            };
            serviceConfig = {
              User = "kache";
              Group = "kache";
              ExecStart = "${kache} daemon run";
              # It restarts itself when /etc/kache/config.toml changes.
              Restart = "always";
              RestartSec = 5;
              RuntimeDirectory = "kache";
              RuntimeDirectoryMode = "0700";
              StateDirectory = "kache";
              UMask = "0007";
              Nice = 19;
              IOSchedulingClass = "idle";
              ProtectSystem = "strict";
              ReadWritePaths = [ store ];
              ProtectHome = "read-only";
              PrivateTmp = true;
              PrivateDevices = true;
              NoNewPrivileges = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              RestrictSUIDSGID = true;
            };
          };

        }
        {
          # The runners: the store writable through ProtectSystem=strict
          # (`-`: a unit still starts without the drive), and kache as Cargo's
          # rustc wrapper for every job. RUSTC_WRAPPER is an environment
          # variable rather than Cargo config because the studio and task jobs
          # bring their own CARGO_HOME; a job opts out with RUSTC_WRAPPER="".
          systemd.services = lib.mapAttrs' (
            name: _:
            lib.nameValuePair "github-runner-${name}" {
              wants = [ "kache-store.service" ];
              after = [ "kache-store.service" ];
              environment = {
                RUSTC_WRAPPER = kache;
                KACHE_RUNTIME_DIR = "/var/lib/github-runner/${name}/kache";
                # One for every runner (one uid), so all of them key alike.
                KACHE_OUT_DIR_ALIAS_ROOT = "${store}/out-dirs-github-runner";
              };
              serviceConfig.ReadWritePaths = [ "-${store}" ];
            }
          ) runners;
        }
      ];
  };

  # The store's daemon is the system one above.
  den.aspects."cody@THEBATTLESHIP".homeManager.kache.userDaemon = false;
}
