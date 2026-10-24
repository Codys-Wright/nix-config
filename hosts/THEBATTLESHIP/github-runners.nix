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
  # every merge to main and every release build runs here, each on its own
  # instance so each keeps its own warm target dir in $CI_CACHE_DIR
  # (studio's checks.yml caps it at 200 GB). `studio-main` takes the merges
  # (a newer merge cancels the older run); `studio-release` takes the
  # release commits, which queue and always run to the end, so a release
  # never waits behind ordinary merges. Registered through the FTS - Forge
  # GitHub App, like github-starcommand: a fresh registration token on every
  # start, no stored token to expire (the shared `github-runner-token`
  # returned 401 when these were first added, 2026-10-24).
  studio = {
    github-fts-studio-main = "studio-main";
    github-fts-studio-release = "studio-release";
  };
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
    # Task's CI (checks per build kind, plan, desktop-cache and the release
    # deploy) runs on the Mac Pro VM, not here (Captain, 2026-10-22: free
    # THEBATTLESHIP for the engineers' work; supersedes STA-229). The runners
    # live in Codys-Wright/starcommand hosts/toms-mac-pro-vm/github-runners.nix
    # (macpro-task-1, -tests, -lint, -wasm, -deploy).
    # Rollback: restore the `github-fts-task`, `github-fts-task-deploy` and
    # per-kind (`task-tests` x2, `task-lint`, `task-wasm`) runners from git
    # history and switch.
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
      }
    ) studio
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
    in
    {
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
