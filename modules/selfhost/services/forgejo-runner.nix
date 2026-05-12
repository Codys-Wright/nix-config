# Forgejo Actions Runner
#
# Runs CI/CD jobs for a remote Forgejo instance. Designed to run on a powerful
# host (workstation / build server) so that Forgejo itself, hosted on a smaller
# always-on machine, doesn't have to bear the compile/test load.
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  fleet.selfhost._.forgejo-runner =
    {
      # URL of the Forgejo instance to register against
      url ? "https://git.starcommand.live",
      # Human-readable name for this runner instance in the Forgejo admin UI
      name ? "battleship",
      # SOPS-encrypted key holding the runner registration token. The token
      # is one-time: on first start, the runner consumes it and stores its
      # persistent runner secret in /var/lib/gitea-runner/<instance>/.runner.
      tokenKey ? "forgejo/runner_token",
      # Path under hosts/<host>/secrets.yaml — defaults to the same path,
      # matches the conventional `cody/...` style of other secrets here.
      tokenSopsFile ? null,
      # Labels exposed to workflows via `runs-on:`.
      # Defaults pick host-mode for nix/native and Docker-mode for the
      # GitHub-compat `ubuntu-latest` label so third-party actions work.
      labels ? [
        "battleship:host"
        "nix:host"
        "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
      ],
      # Max concurrent jobs. Battleship has 32 cores / 192GB but is also a
      # DAW workstation — 8 gives the runner room to burst when battleship
      # is idle (typical agent activity windows) while leaving ~24 cores
      # reliably free for interactive work. The cgroup priority knobs below
      # let the runner yield further when there's real contention, so this
      # number caps the burst rather than dictating constant load.
      capacity ? 8,
      # Per-job wall-clock cap. Long compiles need room; runaway jobs don't.
      timeout ? "3h",
      # Linux scheduling priority for the runner. Lower than the default
      # niceness (0) so audio / interactive work pre-empts the runner when
      # they need CPU. -1..19; 10 means "half-as-eager as default."
      nice ? 10,
      # CPU/IO/IO-burst cgroup weights (1..10000, default 100). Halving
      # them on the runner yields gracefully to anything else on the box.
      cpuWeight ? 50,
      ioWeight ? 50,
      ...
    }:
    { class, aspect-chain, ... }:
    {
      description = ''
        Forgejo Actions runner pointed at ${url}.

        Runs CI jobs on this host so the Forgejo server can stay light. First
        deploy consumes the one-time registration token; subsequent restarts
        use the persisted runner credentials.
      '';

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          # The runner needs Docker to back the `ubuntu-latest:docker://…`
          # label. The `host` labels run jobs directly on the box and don't
          # need it, but enabling it here is the path of least surprise so
          # any imported workflow that says `runs-on: ubuntu-latest` works.
          virtualisation.docker.enable = lib.mkDefault true;

          # Pre-create the runner user/group so the SOPS owner reference
          # below resolves at activation time. The gitea-actions-runner
          # module ordinarily creates these, but only at the moment its
          # systemd unit activates — which is too late for sops-install-secrets
          # to chown the token file.
          users.users.gitea-runner = {
            isSystemUser = true;
            group = "gitea-runner";
            description = "Forgejo Actions runner";
            home = "/var/lib/gitea-runner";
            # Add docker so this user can spawn `runs-on: ubuntu-latest`
            # jobs in the host's Docker daemon.
            extraGroups = [ "docker" ];
          };
          users.groups.gitea-runner = { };

          # Registration token (one-time use). SOPS-encrypted.
          #
          # The nixpkgs gitea-actions-runner module consumes `tokenFile` as a
          # systemd EnvironmentFile and expects it to define TOKEN=..., not to
          # contain the raw registration token. Keep the raw secret private, then
          # render a tiny env file with the sops-nix placeholder substitution.
          sops.secrets.${tokenKey} = {
            sopsFile = lib.mkIf (tokenSopsFile != null) tokenSopsFile;
            owner = "gitea-runner";
            group = "gitea-runner";
            mode = "0400";
            restartUnits = [ "gitea-runner-${name}.service" ];
          };
          sops.templates."forgejo-runner-${name}-token-env" = {
            content = ''
              TOKEN=${config.sops.placeholder.${tokenKey}}
            '';
            owner = "gitea-runner";
            group = "gitea-runner";
            mode = "0400";
            restartUnits = [ "gitea-runner-${name}.service" ];
          };

          services.gitea-actions-runner = {
            package = pkgs.forgejo-runner;
            instances.${name} = {
              enable = true;
              inherit name url labels;
              tokenFile = config.sops.templates."forgejo-runner-${name}-token-env".path;
              settings = {
                log.level = "info";
                runner = {
                  capacity = capacity;
                  timeout = timeout;
                  # Don't pre-pull every label's image at startup — saves
                  # disk and time when the runner first comes up.
                  fetch_timeout = "10s";
                  fetch_interval = "5s";
                };
                cache = {
                  enabled = true;
                  dir = "/var/lib/gitea-runner/${name}/cache";
                };
                container = {
                  # Run docker-backed jobs as the host's Docker daemon, no
                  # privileged mode by default.
                  privileged = false;
                  network = "bridge";
                  # Mount the runner's nix store as read-only into containers
                  # so nix-based actions can reuse the host's binary cache.
                  options = "-v /nix/store:/nix/store:ro";
                };
                host = {
                  # Workdir for `runs-on: nix:host` / `battleship:host` jobs.
                  workdir_parent = "/var/lib/gitea-runner/${name}/work";
                };
              };
            };
          };

          # Cgroup + scheduling priority. Lets the runner burst to `capacity`
          # jobs when battleship is idle, but yields to interactive work
          # (DAW, terminal, anything you're actively doing) the moment
          # there's contention. RT-priority audio threads are unaffected
          # either way; this just keeps the non-RT side of your workload
          # responsive while CI is grinding.
          # When this host is also a deploy target, nixos activation will
          # stop+restart the runner because its own unit definition changed
          # — which kills the in-flight CD job that triggered the rebuild
          # in the first place. Pin BOTH restartIfChanged and stopIfChanged
          # to false: restartIfChanged alone leaves stopIfChanged at its
          # true default, which still issues a stop before the new unit
          # picks up. With both false, activation updates the unit symlink
          # but leaves the running process alone. After a runner-config
          # change you must manually run
          #   systemctl restart gitea-runner-${name}
          # once the deploy completes for the new settings to take effect.
          systemd.services."gitea-runner-${name}" = {
            restartIfChanged = false;
            stopIfChanged = false;
            serviceConfig = {
              # Upstream defaults to DynamicUser=true, which races with the
              # sops-owned token (chowned to the static `gitea-runner` we
              # declare above). Pin to the static user/group so the runner
              # can actually read its registration token at start.
              DynamicUser = lib.mkForce false;
              User = lib.mkForce "gitea-runner";
              Group = lib.mkForce "gitea-runner";
              Nice = nice;
              CPUWeight = cpuWeight;
              IOWeight = ioWeight;
              # When you're mixing, you don't want the runner stealing
              # large blocks of CPU at once.  CPUQuota caps the runner's
              # total CPU share to roughly `capacity * 200%` (i.e. 2 cores
              # of headroom per concurrent job, with the rest being burst).
              # 8 jobs * 200% = 1600%.  battleship has 3200% available so
              # this still allows the runner to use half the box at peak.
              CPUQuota = "${toString (capacity * 200)}%";
            };
          };

          # State + cache dirs (the systemd unit's StateDirectory= covers
          # /var/lib/gitea-runner/${name} but be explicit about subdirs).
          systemd.tmpfiles.rules = [
            "d /var/lib/gitea-runner/${name}        0750 gitea-runner gitea-runner -"
            "d /var/lib/gitea-runner/${name}/cache  0750 gitea-runner gitea-runner -"
            "d /var/lib/gitea-runner/${name}/work   0750 gitea-runner gitea-runner -"
            # DynamicUser previously created /var/lib/private/gitea-runner and
            # systemd migrated it back when DynamicUser was disabled. Recursively
            # normalize the existing state tree so the static runner can replace
            # .runner and .labels during registration.
            "Z /var/lib/gitea-runner             0750 gitea-runner gitea-runner -"
          ];
        };
    };
}
