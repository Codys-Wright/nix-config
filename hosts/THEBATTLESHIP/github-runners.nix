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
    in
    {
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
        );

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
    };
}
