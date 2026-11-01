# THEBATTLESHIP's GitHub Actions runners (org FastTrackStudios), ported from
# the fix/argocd-task-github-path branch (2026-09-04), where they were set up.
#
# One runner per project. A slot is not capacity — all of them share these
# 32 cores — but a slot IS a cache: each instance's target dir holds one
# project's artifacts, so it stays warm and is never evicted by another
# project's build, and one project's burst never queues another's
# two-minute check. Work trees and caches live on /run/media/Development
# (`storageRoot`), where the space is; jobs find their cache as
# $CI_CACHE_DIR. Each repo picks its runner with
# `runs-on: [self-hosted, <label>]`.
#
# The aspect's defaults (Nice=10, CPUWeight/IOWeight=50) keep a runner from
# being audible under a DAW session. Here CI gets the full box at normal
# priority (the wait on a PR is what's being protected); drop `nice` and
# the weights from `runner` below to restore the defaults.
{ inputs, fleet, ... }:
let
  runner =
    args:
    fleet.ci._.github-runner (
      {
        tokenSopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
        nice = 0;
        cpuWeight = 100;
        ioWeight = 100;
        storageRoot = "/run/media/Development";
        workRoot = "/run/media/Development/github-runner-work";
      }
      // args
    );
  # name → label, one runner each.
  perProject = {
    github-fts-architect = "architect";
    github-fts-auth = "auth";
    github-fts-signal = "signal";
    github-fts-session = "session";
    github-fts-keyflow = "keyflow";
    github-fts-ignition = "ignition";
    github-fts-daw = "daw";
    # Two smaller repos that still build Rust often enough to want a warm
    # cache of their own; the other small repos stay on hosted runners.
    github-fts-editor = "editor";
    github-fts-extensions = "fts-extensions";
  };
  # Studio (FastTrackStudios/studio): PRs run on GitHub's free runners;
  # every merge to main and every release build runs here. Two POOLS of
  # three instances: `studio-main` takes the merges (a newer merge cancels
  # the older run), `studio-release` the release commits (queued, never
  # cancelled), so a release never waits behind ordinary merges. A run's
  # Check, Tests and Wasm jobs are claimed by three instances of one pool at
  # once. The pool's instances share one cache, $STUDIO_CACHE_DIR
  # (<storageRoot>/ci/<pool>), where each build kind keeps its own target dir
  # (check mode, test codegen and wasm32 share no artifacts), so every
  # instance builds warm; studio's checks.yml caps a pool at 200 GB.
  # Registered through the FTS - Forge GitHub App, like github-starcommand:
  # a fresh registration token on every start, no stored token to expire
  # (the shared `github-runner-token` returned 401, 2026-10-24).
  studioPools = {
    github-fts-studio-main = "studio-main";
    github-fts-studio-release = "studio-release";
  };
  studioCount = 3;
  studioCache = pool: "/run/media/Development/ci/${pool}";
  # Task (FastTrackStudios/task): the same shape as Studio's. PR checks stay
  # on the author's machine (Local CI) and GitHub's free runners. The pools
  # split by CACHE, not by event: `task-main` runs every dev-profile check
  # build (checks.yml for each merge to main, a release commit's included:
  # the same units, on the same warm dirs; a newer merge cancels the older
  # run, a release commit's never), `task-release` only the release-profile
  # artifacts (images, the desktop cache; queued, never cancelled). Three
  # instances a pool, so a run's Lint, Tests and Wasm build at once; the
  # pool's instances share $TASK_CACHE_DIR, one target dir per build kind,
  # so a merge compiles only what it changed. Every instance runs taskJobGate (below): the repo is
  # public, so nothing but code already on main, release/v* or a v* tag runs
  # here. (Captain, 2026-10-24: main merges come back to THEBATTLESHIP;
  # supersedes the 2026-10-22 move to the Mac Pro VM, whose macpro-task-*
  # runners no Task workflow targets any more.)
  taskPools = {
    github-fts-task-main = "task-main";
    github-fts-task-release = "task-release";
  };
  taskCount = 3;
  taskCache = pool: "/run/media/Development/ci/${pool}";
  forgeApp = {
    id = 5391924;
    login = "FastTrackStudios";
    keySopsKey = "github_app_fts_forge_private_key";
    keySopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
  };

  # ── The generic pools (stage 1 of the consolidation, 2026-10-31) ─────────
  #
  # kache (kache.nix) restores a cold runner's build from the shared store in
  # seconds, so a runner no longer has to be a project's warm target dir.
  # Two pools serve every FastTrackStudios repo; the per-project singles and
  # the studio/task pools above stay until the workflows move (stage 2) and
  # are then removed (stage 3).
  #
  #   github-fts-thebattleship-1..8          label `thebattleship`
  #       every check, test and build job. Eight for 32 threads / 192 GB:
  #       a Rust job rarely keeps more than ~4 threads busy for long (link,
  #       codegen tails), and a restore from kache is mostly I/O.
  #   github-fts-thebattleship-release-1..2  label `thebattleship-release`
  #       tag and release jobs only, so a release never queues behind checks.
  #
  # Both run `ciJobGate` before every job (non-zero fails it before any step):
  #   - the repo must be FastTrackStudios/<repo>, in $GITHUB_REPOSITORY and in
  #     the event payload ($GITHUB_EVENT_PATH) alike;
  #   - a pull request from a fork (head repo != the repo) is always refused;
  #   - visibility is the payload's `.repository.private`, never a list here:
  #       private: any event;
  #       public:  a push to main, release/v* or a v* tag, or workflow_dispatch
  #                (which takes write access); anything else is refused;
  #       unreadable payload or no boolean `private`: refused.
  #
  # ENV CONTRACT — what a job on either pool can rely on (stage 2 workflows
  # use these and nothing host-specific):
  #   CI_POOL          `thebattleship` or `thebattleship-release`. Guard on it
  #                    (`${CI_POOL:?not a thebattleship runner}`).
  #   CI_CACHE_DIR     /run/media/Development/ci/thebattleship/<owner>/<repo>:
  #                    this repo's durable cache, made 0700 github-runner by
  #                    the gate on first use, shared by every instance of both
  #                    pools (so two jobs of one repo may use it at once: give
  #                    each build kind its own subdir, which cargo's lock then
  #                    serialises). Put target dirs here as
  #                    `$CI_CACHE_DIR/<kind>/target` (kache rule: named
  #                    `target`), cargo-rail evidence as
  #                    `$CI_CACHE_DIR/rail-evidence`. (The runner module's own
  #                    per-instance CI_CACHE_DIR is overridden by the gate.)
  #   CARGO_HOME       $CI_CACHE_DIR/cargo-home: one stable cargo home per repo
  #                    (registry, git deps, a repo's CI config.toml; cargo-rail
  #                    evidence keys on it). Write config into it atomically
  #                    (mktemp + mv): jobs share it.
  #   RUSTC_WRAPPER, KACHE_RUNTIME_DIR, KACHE_OUT_DIR_ALIAS_ROOT
  #                    kache, set by kache.nix on every github-runner unit;
  #                    a job opts out with RUSTC_WRAPPER="".
  # Workflows: `runs-on: [self-hosted, thebattleship]` (or
  # `thebattleship-release`). Daily, artifacts untouched for 3 days are swept
  # from every target dir under the pools' cache root.
  genericPools = {
    github-fts-thebattleship = {
      label = "thebattleship";
      count = 8;
    };
    github-fts-thebattleship-release = {
      label = "thebattleship-release";
      count = 2;
    };
  };
  genericCacheRoot = "/run/media/Development/ci/thebattleship";
  genericOrg = "FastTrackStudios";
in
{
  den.aspects.THEBATTLESHIP-github-runners.includes = [
    # The bare `nix-host` pool (github-fts-1, -2): the LAN-only deploys
    # (forum, the landing site) and repos not yet on a label of their own.
    (runner { count = 2; })
    # Codys-Wright/starcommand's own runner: release tags deploy from here
    # (deploy.yml, `runs-on: [self-hosted, starcommand]`). Registered through
    # the FTS - Forge GitHub App (installed on Codys-Wright, all repos), so no
    # PAT; the key is a THEBATTLESHIP host secret.
    (runner {
      name = "github-starcommand";
      url = "https://github.com/Codys-Wright/starcommand";
      labels = [ "starcommand" ];
      githubApp = {
        id = 5391924;
        login = "Codys-Wright";
        keySopsKey = "github_app_fts_forge_private_key";
        keySopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
      };
    })
  ]
  ++ builtins.attrValues (
    builtins.mapAttrs (
      name: label:
      runner {
        inherit name;
        labels = [ label ];
      }
    ) perProject
  )
  ++ builtins.attrValues (
    builtins.mapAttrs (
      name: label:
      runner {
        inherit name;
        labels = [ label ];
        githubApp = forgeApp;
        count = studioCount;
      }
    ) studioPools
  )
  ++ builtins.attrValues (
    builtins.mapAttrs (
      name: label:
      runner {
        inherit name;
        labels = [ label ];
        githubApp = forgeApp;
        count = taskCount;
      }
    ) taskPools
  )
  ++ builtins.attrValues (
    builtins.mapAttrs (
      name: pool:
      runner {
        inherit name;
        inherit (pool) count;
        labels = [ pool.label ];
        githubApp = forgeApp;
      }
    ) genericPools
  );

  # ── starcommand CI deploy credentials (github-starcommand only) ──────────
  #
  # deploy.yml in Codys-Wright/starcommand deploys a release tag (vX.Y.Z)
  # to production from this runner. Its jobs run as a DEDICATED user, `starcommand-ci`, so the
  # 14 FastTrackStudios runners (user github-runner, which run PR code) can
  # never read these keys. Both keys come from nix-secrets
  # sops/ci/starcommand-deploy.yaml, encrypted only to cody + this host and
  # decrypted here at activation; no age identity is exposed to any job.
  #
  #   DEPLOY_SSH_KEY_FILE  root@starcommand, authorized there with
  #                        from="10.10.10.10" and no forwarding
  #   GIT_SSH_COMMAND      read-only deploy key on Codys-Wright/nix-secrets
  #                        (the starcommand flake input), pinned github.com
  #
  # A job-started hook refuses every job that is not deploy.yml on a vX.Y.Z
  # tag via push / workflow_dispatch, whatever a branch's workflow file says.
  #
  # Revoke: remove the key line from starcommand's root authorized keys and
  # the nix-secrets deploy key "starcommand-ci (THEBATTLESHIP, read-only)",
  # then drop this block. Design: starcommand docs/ci-deploy.md.
  den.aspects.THEBATTLESHIP-github-runners.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      unit = "github-runner-github-starcommand";
      ciSops = "${inputs.nix-secrets}/sops/ci/starcommand-deploy.yaml";
      secret = key: {
        sopsFile = ciSops;
        inherit key;
        owner = "starcommand-ci";
        group = "starcommand-ci";
        mode = "0400";
        restartUnits = [ "${unit}.service" ];
      };
      githubKnownHosts = pkgs.writeText "github-known-hosts" ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
      '';
      jobGate = pkgs.writeShellScript "starcommand-ci-job-gate.sh" ''
        # ACTIONS_RUNNER_HOOK_JOB_STARTED (the runner requires a .sh name):
        # non-zero fails the job before any
        # of its steps run.
        # Only a release tag deploys (starcommand is trunk-based: merging
        # into main deploys nothing; `just release-tag` pushes vX.Y.Z).
        ref="''${GITHUB_REF:-}"
        deny() { echo "starcommand-ci: refusing job ($1)" >&2; exit 1; }
        [ "''${GITHUB_REPOSITORY:-}" = "Codys-Wright/starcommand" ] || deny "repository ''${GITHUB_REPOSITORY:-?}"
        [[ "$ref" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$ ]] || deny "ref ''${ref:-?}"
        [ "''${GITHUB_WORKFLOW_REF:-}" = "Codys-Wright/starcommand/.github/workflows/deploy.yml@$ref" ] || deny "workflow ''${GITHUB_WORKFLOW_REF:-?}"
        case "''${GITHUB_EVENT_NAME:-}" in
          push) ;;
          workflow_dispatch) [ "''${GITHUB_ACTOR:-}" = "Codys-Wright" ] || deny "dispatch by ''${GITHUB_ACTOR:-?}" ;;
          *) deny "event ''${GITHUB_EVENT_NAME:-?}" ;;
        esac
      '';
      studioInstances = lib.concatLists (
        lib.mapAttrsToList (
          name: pool:
          map (i: {
            unit = "github-runner-${name}-${toString i}";
            inherit pool;
          }) (lib.range 1 studioCount)
        ) studioPools
      );
      # The Task runners' gate. FastTrackStudios/task is PUBLIC, and a
      # workflow in a fork's PR can name any label: without this, a PR could
      # run its own code on this host with the pools' warm caches. Only code
      # already on the repo's protected refs runs here — a push to main, a
      # release/v* hotfix branch or a v* tag (deploy.yml's called workflows
      # report the tag push) — or a manual dispatch, which takes write
      # access to the repo.
      taskJobGate = pkgs.writeShellScript "task-ci-job-gate.sh" ''
        ref="''${GITHUB_REF:-}"
        deny() { echo "task-ci: refusing job ($1)" >&2; exit 1; }
        [ "''${GITHUB_REPOSITORY:-}" = "FastTrackStudios/task" ] || deny "repository ''${GITHUB_REPOSITORY:-?}"
        case "''${GITHUB_EVENT_NAME:-}" in
          push)
            [[ "$ref" == refs/heads/main || "$ref" =~ ^refs/heads/release/v[0-9] || "$ref" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$ ]] \
              || deny "push to ''${ref:-?}" ;;
          workflow_dispatch) ;;
          *) deny "event ''${GITHUB_EVENT_NAME:-?}" ;;
        esac
      '';
      taskInstances = lib.concatLists (
        lib.mapAttrsToList (
          name: pool:
          map (i: {
            unit = "github-runner-${name}-${toString i}";
            inherit pool;
          }) (lib.range 1 taskCount)
        ) taskPools
      );
      # The generic pools' gate (rules in the comment at the top), then the
      # repo's cache dir and cargo home handed to the job's steps through
      # $GITHUB_ENV. Every fact comes from the job's own environment and
      # event payload; anything missing or unreadable is a refusal.
      ciJobGate = pkgs.writeShellApplication {
        # The runner runs a hook only if its name ends in .sh.
        name = "fts-ci-job-gate.sh";
        runtimeInputs = [
          pkgs.jq
          pkgs.coreutils
        ];
        text = ''
          org=${genericOrg}
          root=${genericCacheRoot}
          deny() { echo "fts-ci: refusing job ($1)" >&2; exit 1; }

          repo="''${GITHUB_REPOSITORY:-}"
          event="''${GITHUB_EVENT_NAME:-}"
          ref="''${GITHUB_REF:-}"
          payload="''${GITHUB_EVENT_PATH:-}"

          [[ "$repo" =~ ^''${org}/[A-Za-z0-9._-]+$ ]] || deny "repository ''${repo:-?}"
          name="''${repo#*/}"
          [[ "$name" != . && "$name" != .. ]] || deny "repository $repo"
          [ "''${GITHUB_REPOSITORY_OWNER:-}" = "$org" ] || deny "owner ''${GITHUB_REPOSITORY_OWNER:-?}"
          [ -n "$payload" ] && [ -r "$payload" ] || deny "no event payload"

          # One jq pass, one fact a line (no name holds a newline): the
          # payload's repo, owner, visibility and, for a pull request, whether
          # its head is this repo. jq -e fails on malformed JSON.
          facts="$(jq -er '[
              (.repository.full_name // ""),
              (.repository.owner.login // ""),
              (.repository.private | if type == "boolean" then tostring else "unknown" end),
              (if has("pull_request") then
                 (if (.pull_request.head.repo.full_name // "") == .repository.full_name
                  then "same" else "fork" end)
               else "none" end)
            ] | .[]' "$payload" 2>/dev/null)" || deny "unreadable event payload"
          mapfile -t f <<<"$facts"
          [ "''${#f[@]}" -eq 4 ] || deny "unreadable event payload"
          p_repo="''${f[0]}" p_owner="''${f[1]}" private="''${f[2]}" pr="''${f[3]}"

          [ "$p_repo" = "$repo" ] || deny "payload repository ''${p_repo:-?} != $repo"
          [ "$p_owner" = "$org" ] || deny "payload owner ''${p_owner:-?}"
          [ "$pr" != fork ] || deny "pull request from a fork"

          case "$private" in
            true) why="private repo, $event" ;;
            false)
              case "$event" in
                push)
                  [[ "$ref" == refs/heads/main || "$ref" =~ ^refs/heads/release/v[0-9] || "$ref" =~ ^refs/tags/v[0-9] ]] \
                    || deny "public repo, push to ''${ref:-?}"
                  why="public repo, push to $ref" ;;
                workflow_dispatch) why="public repo, workflow_dispatch" ;;
                *) deny "public repo, event ''${event:-?}" ;;
              esac ;;
            *) deny "repository visibility unknown" ;;
          esac

          dir="$root/$org/$name"
          install -d -m 0700 "$root/$org" "$dir" "$dir/cargo-home"
          [ -n "''${GITHUB_ENV:-}" ] || deny "no GITHUB_ENV"
          {
            echo "CI_CACHE_DIR=$dir"
            echo "CARGO_HOME=$dir/cargo-home"
          } >>"$GITHUB_ENV"
          echo "fts-ci: allowed ($why); CI_POOL=''${CI_POOL:-?} CI_CACHE_DIR=$dir"
        '';
      };
      genericInstances = lib.concatLists (
        lib.mapAttrsToList (
          name: pool:
          map (i: {
            unit = "github-runner-${name}-${toString i}";
            inherit (pool) label;
          }) (lib.range 1 pool.count)
        ) genericPools
      );
    in
    {
      # The generic pools' cache root: per-repo dirs under it are made by the
      # gate, as github-runner, on a repo's first job.
      system.activationScripts.generic-runner-cache-root = lib.stringAfter [ "users" "groups" ] ''
        install -d -m 0700 -o github-runner -g github-runner ${genericCacheRoot}
      '';
      # The pools' shared caches ($STUDIO_CACHE_DIR, $TASK_CACHE_DIR): made at
      # activation like the module's own dirs on this disk (tmpfiles refuses
      # the cody-owned mount as a parent), writable by every instance of the
      # pool, and named to each job.
      system.activationScripts.studio-runner-pool-caches = lib.stringAfter [ "users" "groups" ] (
        lib.concatMapStringsSep "\n" (
          pool: "install -d -m 0700 -o github-runner -g github-runner ${studioCache pool}"
        ) (lib.unique (builtins.attrValues studioPools))
      );
      system.activationScripts.task-runner-pool-caches = lib.stringAfter [ "users" "groups" ] (
        lib.concatMapStringsSep "\n" (
          pool: "install -d -m 0700 -o github-runner -g github-runner ${taskCache pool}"
        ) (lib.unique (builtins.attrValues taskPools))
      );
      systemd.services =
        lib.listToAttrs (
          map (inst: {
            name = inst.unit;
            value.serviceConfig = {
              ReadWritePaths = [ (studioCache inst.pool) ];
              Environment = [ "STUDIO_CACHE_DIR=${studioCache inst.pool}" ];
            };
          }) studioInstances
        )
        // lib.listToAttrs (
          map (inst: {
            name = inst.unit;
            value = {
              # nicknovitski/nix-develop (how checks.yml enters `.#ci`)
              # needs openssl for its env-file delimiters; the module's PATH
              # is a short explicit list without it (exit 127, 2026-10-24).
              path = with pkgs; [
                openssl
                jq
              ];
              serviceConfig = {
                ReadWritePaths = [ (taskCache inst.pool) ];
                Environment = [
                  "TASK_CACHE_DIR=${taskCache inst.pool}"
                  # The runner runs this before every job; non-zero fails it
                  # before any step.
                  "ACTIONS_RUNNER_HOOK_JOB_STARTED=${taskJobGate}"
                ];
              }
              # task-release only: the Flatpak build (Task's
              # scripts/desktop/linux.sh) has flatpak validate the exported
              # icon under bwrap, which needs a user namespace and a fresh /proc
              # mounted inside it. Measured 2026-10-24 with transient system
              # units as github-runner and this unit's settings: these four
              # block it (ProtectHostname only in combination with the rest),
              # plus the default syscall deny list (mount, capset, chroot…);
              # PrivateUsers, NoNewPrivileges, ProtectSystem, ProtectHome,
              # ProtectProc, PrivateDevices and the empty capability bounding
              # set don't, and stay. The job gate still admits only protected
              # refs, and task-main keeps every default.
              // lib.optionalAttrs (inst.pool == "task-release") {
                RestrictNamespaces = lib.mkForce false;
                ProtectKernelTunables = lib.mkForce false;
                ProtectKernelLogs = lib.mkForce false;
                ProtectHostname = lib.mkForce false;
                SystemCallFilter = lib.mkForce [
                  "@system-service"
                  "@mount"
                  "pivot_root"
                  "capset"
                  "chroot"
                ];
              };
            };
          }) taskInstances
        )
        // lib.listToAttrs (
          map (inst: {
            name = inst.unit;
            value = {
              # The gate's jq; openssl for nix-develop's env-file delimiters,
              # as on the task pools.
              path = with pkgs; [
                openssl
                jq
              ];
              serviceConfig = {
                ReadWritePaths = [ genericCacheRoot ];
                Environment = [
                  "CI_POOL=${inst.label}"
                  "ACTIONS_RUNNER_HOOK_JOB_STARTED=${lib.getExe ciJobGate}"
                ];
              };
            };
          }) genericInstances
        )
        // {
          # Daily sweep of every target dir under the generic pools' cache
          # root (a `.rustc_info.json` marks one; cargo homes have none):
          # artifacts no build touched in 3 days go, so a long-lived per-repo
          # cache does not grow forever.
          github-runner-sweep-thebattleship = {
            description = "cargo sweep of the generic runner pools' per-repo caches";
            startAt = "04:45";
            path = [
              pkgs.cargo
              pkgs.cargo-sweep
              pkgs.findutils
            ];
            serviceConfig = {
              Type = "oneshot";
              User = "github-runner";
              Group = "github-runner";
              Nice = 19;
              IOSchedulingClass = "idle";
            };
            script = ''
              [ -d ${genericCacheRoot} ] || exit 0
              pkg=$(mktemp -d)
              trap 'rm -rf "$pkg"' EXIT
              mkdir "$pkg/src"
              printf '[package]\nname = "sweep"\nversion = "0.0.0"\nedition = "2021"\n' > "$pkg/Cargo.toml"
              echo 'fn main() {}' > "$pkg/src/main.rs"
              find ${genericCacheRoot} -maxdepth 6 -name .rustc_info.json -printf '%h\n' |
                while read -r target; do
                  CARGO_TARGET_DIR="$target" cargo sweep --time 3 "$pkg" || true
                done
            '';
          };
        };

      users.users.starcommand-ci = {
        isSystemUser = true;
        group = "starcommand-ci";
        description = "starcommand CI deploy (github-starcommand runner)";
        home = "/var/lib/starcommand-ci";
        createHome = true;
      };
      users.groups.starcommand-ci = { };

      sops.secrets."starcommand-ci/deploy-ssh-key" = secret "ci_deploy_ssh_key";
      sops.secrets."starcommand-ci/nix-secrets-read-key" = secret "nix_secrets_read_key";

      # ACCEPTED RISK (Captain, 2026-10-20): github_app_fts_forge_private_key
      # stays github-runner 0400, so jobs on the 14 FastTrackStudios runners
      # (user github-runner) can read it and mint fts-forge App tokens. This
      # runner is unaffected: it runs as starcommand-ci, and only the
      # privileged (`+`) ExecStartPre reads the key. Suggested fix, not
      # applied: owner root, mint tokens only in the `+` step. See
      # starcommand docs/ci-deploy.md.

      services.github-runners.github-starcommand = {
        user = lib.mkForce "starcommand-ci";
        group = lib.mkForce "starcommand-ci";
        # The shared work root is github-runner's; the starcommand checkout
        # is small, so the unit's own RuntimeDirectory is fine.
        workDir = lib.mkForce null;
        extraEnvironment = {
          DEPLOY_SSH_KEY_FILE = config.sops.secrets."starcommand-ci/deploy-ssh-key".path;
          GIT_SSH_COMMAND = "ssh -i ${
            config.sops.secrets."starcommand-ci/nix-secrets-read-key".path
          } -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${githubKnownHosts}";
          ACTIONS_RUNNER_HOOK_JOB_STARTED = "${jobGate}";
        };
        extraPackages = with pkgs; [
          openssh
          rsync
          jq
        ];
      };

      # One job kind per Task instance. A target dir is warm only for the
      # ~/.cargo and checkout paths that built it, and each instance has its
      # own, so Task's workflows keep one target dir per kind per instance
      # ($TASK_CACHE_DIR/<kind>-<runner>) and pin each kind to one instance
      # by these labels: the same runner builds it every time, on the dir it
      # left warm. (Shared dirs made every job that changed instance
      # recompile all ~1,575 units.) images is prod's critical path, so it
      # has an instance to itself.
      services.github-runners.github-fts-task-main-1.extraLabels = [ "task-main-tests" ];
      services.github-runners.github-fts-task-main-2.extraLabels = [ "task-main-lint" ];
      services.github-runners.github-fts-task-main-3.extraLabels = [ "task-main-wasm" ];
      services.github-runners.github-fts-task-release-1.extraLabels = [ "task-release-images" ];
      services.github-runners.github-fts-task-release-2.extraLabels = [ "task-release-node" ];
      services.github-runners.github-fts-task-release-3.extraLabels = [ "task-release-desktop" ];
    };
}
