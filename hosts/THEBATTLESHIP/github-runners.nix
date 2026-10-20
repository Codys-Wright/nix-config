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
in
{
  den.aspects.THEBATTLESHIP-github-runners.includes = [
    # The bare `nix-host` pool (github-fts-1, -2): the LAN-only deploys
    # (forum, the landing site) and repos not yet on a label of their own.
    (runner { count = 2; })
    # Task's deploy gets a slot of its own: with checks and deploy sharing
    # the `task` runners, a deploy sat 45 minutes behind two PRs' test
    # builds. Its cache holds the release target dir the deploy fast path
    # builds incrementally.
    (runner {
      name = "github-fts-task-deploy";
      labels = [ "task-deploy" ];
    })
    # Two: a deploy takes ~30 min of nix build and must not queue the next
    # PR's checks behind it.
    (runner {
      name = "github-fts-task";
      labels = [ "task" ];
      count = 2;
    })
    # Codys-Wright/starcommand's own runner: merges to main deploy from here
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
  );

  # ── starcommand CI deploy credentials (github-starcommand only) ──────────
  #
  # deploy.yml in Codys-Wright/starcommand deploys main to production from
  # this runner. Its jobs run as a DEDICATED user, `starcommand-ci`, so the
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
  # A job-started hook refuses every job that is not deploy.yml on main via
  # push / workflow_dispatch, whatever a branch's workflow file says.
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
      jobGate = pkgs.writeShellScript "starcommand-ci-job-gate" ''
        # ACTIONS_RUNNER_HOOK_JOB_STARTED: non-zero fails the job before any
        # of its steps run.
        want="Codys-Wright/starcommand/.github/workflows/deploy.yml@refs/heads/main"
        deny() { echo "starcommand-ci: refusing job ($1)" >&2; exit 1; }
        [ "''${GITHUB_REPOSITORY:-}" = "Codys-Wright/starcommand" ] || deny "repository ''${GITHUB_REPOSITORY:-?}"
        [ "''${GITHUB_REF:-}" = "refs/heads/main" ] || deny "ref ''${GITHUB_REF:-?}"
        [ "''${GITHUB_WORKFLOW_REF:-}" = "$want" ] || deny "workflow ''${GITHUB_WORKFLOW_REF:-?}"
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
      # BOOTSTRAP ONLY: the dedicated key above is authorized on starcommand
      # by the first CI deploy itself, so that one run uses the existing
      # starcommand deploy key (this host is already a recipient of
      # starcommand.yaml). Removed as soon as that deploy lands.
      sops.secrets."starcommand-ci/bootstrap-deploy-ssh-key" =
        (secret "starcommand/system/sshPrivateKey")
        // {
          sopsFile = "${inputs.nix-secrets}/sops/hosts/starcommand.yaml";
        };

      # The App key only mints registration tokens, in the unit's privileged
      # (`+`) ExecStartPre. Root-only, so no runner job on this host (all
      # 15 runners' jobs run as non-root users) can read it.
      sops.secrets.github_app_fts_forge_private_key = {
        owner = lib.mkForce "root";
        group = lib.mkForce "root";
      };

      services.github-runners.github-starcommand = {
        user = lib.mkForce "starcommand-ci";
        group = lib.mkForce "starcommand-ci";
        # The shared work root is github-runner's; the starcommand checkout
        # is small, so the unit's own RuntimeDirectory is fine.
        workDir = lib.mkForce null;
        extraEnvironment = {
          DEPLOY_SSH_KEY_FILE = config.sops.secrets."starcommand-ci/bootstrap-deploy-ssh-key".path;
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
