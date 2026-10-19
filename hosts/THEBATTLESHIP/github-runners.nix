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
}
