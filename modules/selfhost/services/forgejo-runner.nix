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
      # SOPS-encrypted key holding a pre-created runner's UUID (Codeberg
      # "Create runner" flow). When set, registration is skipped entirely:
      # the daemon connects with --uuid/--token-url (forgejo-runner ≥ 9)
      # and tokenKey holds the runner secret shown at creation time, not a
      # registration token.
      uuidKey ? null,
      # Path under hosts/<host>/secrets.yaml — defaults to the same path,
      # matches the conventional `cody/...` style of other secrets here.
      tokenSopsFile ? null,
      # Container engine backing the `docker://` labels: "podman" (default)
      # or "docker". Podman talks via its docker-compatible API socket at
      # /run/podman/podman.sock — no Docker daemon needed.
      backend ? "podman",
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
        let
          # Shared runner settings (config.yml shape) for both flows.
          runnerSettings = {
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
              # Run docker-backed jobs against the configured engine, no
              # privileged mode by default.
              privileged = false;
              network = "bridge";
              # Mount the runner's nix store as read-only into containers
              # so nix-based actions can reuse the host's binary cache.
              options = "-v /nix/store:/nix/store:ro";
            }
            // lib.optionalAttrs (backend == "podman") {
              # Podman's docker-compatible API socket (root podman,
              # group-gated to `podman`, which gitea-runner joins below).
              docker_host = "unix:///run/podman/podman.sock";
            };
            host = {
              # Workdir for host-label jobs.
              workdir_parent = "/var/lib/gitea-runner/${name}/work";
            };
          };
        in
        lib.mkMerge [
          {
            # The runner needs a container engine to back the `docker://…`
            # labels. The `host` labels run jobs directly on the box and don't
            # need it, but enabling it here is the path of least surprise so
            # any imported workflow that says `runs-on: ubuntu-latest` works.
            virtualisation.docker.enable = lib.mkIf (backend == "docker") (lib.mkDefault true);
            virtualisation.podman.enable = lib.mkIf (backend == "podman") (lib.mkDefault true);

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
              # Engine socket access so this user can spawn `runs-on:
              # ubuntu-latest` jobs (podman socket is group-gated to `podman`,
              # docker's to `docker`).
              extraGroups = [ backend ];
            };
            users.groups.gitea-runner = { };

            # Runner token. SOPS-encrypted. Register flow: one-time
            # registration token. UUID flow: the pre-created runner's secret.
            sops.secrets.${tokenKey} = {
              sopsFile = lib.mkIf (tokenSopsFile != null) tokenSopsFile;
              owner = "gitea-runner";
              group = "gitea-runner";
              mode = "0400";
              restartUnits = [ "gitea-runner-${name}.service" ];
            };

            # Cgroup + scheduling priority. Lets the runner burst to `capacity`
            # jobs when battleship is idle, but yields to interactive work
            # (DAW, terminal, anything you're actively doing) the moment
            # there's contention. RT-priority audio threads are unaffected
            # either way; this just keeps the non-RT side of your workload
            # responsive while CI is grinding.
            systemd.services."gitea-runner-${name}".serviceConfig = {
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
          }

          # ── Register flow ────────────────────────────────────────────────
          # Classic registration-token flow via the nixpkgs module.
          (lib.mkIf (uuidKey == null) {
            # The nixpkgs gitea-actions-runner module consumes `tokenFile` as a
            # systemd EnvironmentFile and expects it to define TOKEN=..., not to
            # contain the raw registration token. Keep the raw secret private,
            # then render a tiny env file with sops-nix placeholder substitution.
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
                settings = runnerSettings;
              };
            };
          })

          # ── Pre-created (UUID) flow ──────────────────────────────────────
          # Codeberg's "Create runner" UI hands out a UUID + secret; there is
          # no registration step. Run the daemon directly with
          # --uuid/--token-url. Both values are read from sops at runtime so
          # neither lands in the nix store.
          (lib.mkIf (uuidKey != null) {
            sops.secrets.${uuidKey} = {
              sopsFile = lib.mkIf (tokenSopsFile != null) tokenSopsFile;
              owner = "gitea-runner";
              group = "gitea-runner";
              mode = "0400";
              restartUnits = [ "gitea-runner-${name}.service" ];
            };

            systemd.services."gitea-runner-${name}" = {
              description = "Forgejo Actions runner for ${url} (pre-registered)";
              wantedBy = [ "multi-user.target" ];
              after = [
                "network-online.target"
                (if backend == "podman" then "podman.socket" else "docker.service")
              ];
              wants = [ "network-online.target" ];
              serviceConfig = {
                ExecStart = pkgs.writeShellScript "forgejo-runner-${name}-daemon" ''
                  exec ${lib.getExe pkgs.forgejo-runner} daemon \
                    --config ${
                      pkgs.writeText "forgejo-runner-${name}-config.json" (
                        # JSON is valid YAML; forgejo-runner reads it fine.
                        builtins.toJSON (
                          runnerSettings
                          // {
                            runner = runnerSettings.runner // {
                              inherit labels;
                            };
                          }
                        )
                      )
                    } \
                    --url ${url} \
                    --uuid "$(cat ${config.sops.secrets.${uuidKey}.path})" \
                    --token-url "file://${config.sops.secrets.${tokenKey}.path}"
                '';
                StateDirectory = "gitea-runner/${name}";
                WorkingDirectory = "/var/lib/gitea-runner/${name}";
                Restart = "always";
                RestartSec = "10s";
              };
            };
          })
        ];
    };
}
