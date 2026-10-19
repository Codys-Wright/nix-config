# GitHub Actions Runner
#
# Registers this host as a self-hosted GitHub Actions runner. Mirrors the
# forgejo-runner aspect but targets GitHub's native runner (the nixpkgs
# `services.github-runners` module) so org workflows (e.g. deploy.yml's
# build+push of NixOS images) can execute on the LAN instead of on hosted
# runners. Org-level by default; the `nix-host` label marks it as carrying
# nix + host tooling for the image-publish jobs.
{
  fleet,
  ...
}:
{
  fleet.ci._.github-runner.__functor =
    _self:
    {
      # Org (or repo) URL to register against. Org-level: use the org root,
      # NOT a single repo, or the registration API returns 404.
      url ? "https://github.com/FastTrackStudios",
      # Human-readable name for this runner in the GitHub runners UI.
      name ? "github-fts",
      # SOPS-encrypted key holding either a fine-grained PAT (org
      # "self-hosted runners: read & write") or a runner registration token.
      # The github-runners module reads this file RAW at `tokenFile` (no
      # TOKEN= env wrapper, unlike the forgejo aspect); a PAT is preferred
      # since registration tokens expire after 1 hour.
      tokenKey ? "github-runner-token",
      # Path under hosts/<host>/… to the sops file carrying tokenKey.
      tokenSopsFile ? null,
      # Labels exposed to workflows via `runs-on:`. `nix-host` marks this
      # runner as host-mode with nix + the image tooling on PATH.
      labels ? [ "nix-host" ],
      # How many runner instances to register. One instance executes ONE
      # job at a time, so a workflow with N parallel jobs serialises on a
      # single runner. Instances are named `<name>-1 .. <name>-N` and each
      # gets its own workDir, so their build trees never contend.
      count ? 1,
      # Parent of each instance's work directory — where the CHECKOUT
      # lands. The nixpkgs module defaults `workDir` to null, which puts it
      # in the unit's RuntimeDirectory (/run/… — tmpfs, charged to RAM).
      # Real disk instead, so a big checkout is not RAM.
      #
      # NOTHING CACHEABLE MAY LIVE HERE. The module's own pre-start hook
      # ends with `find -H "$WORK_DIRECTORY" -mindepth 1 -delete`, run
      # unconditionally on EVERY service start — so a build cache under
      # workDir survives only between jobs of one uninterrupted service
      # lifetime, and is destroyed by any restart, rebuild or reboot. Put
      # build caches in cacheRoot below.
      workRoot ? "/var/lib/github-runner-work",
      # Parent of each instance's BUILD CACHE (e.g. CARGO_TARGET_DIR), as
      # `CacheDirectory=` under /var/cache. This is the durable half:
      # systemd creates it, keeps it across restarts and reboots, and only
      # `systemctl clean --what=cache` removes it. It also has to be a
      # systemd-managed directory rather than a plain path, because the
      # unit runs ProtectSystem=strict — everything outside the state,
      # runtime and cache dirs is read-only to it.
      cacheRoot ? "github-runner-cargo",
      # A big local disk for the DURABLE per-instance build cache, as an
      # absolute path (e.g. "/run/media/Development"). When set, every
      # instance gets `<storageRoot>/ci/<instance>` — created by tmpfiles,
      # writable through ProtectSystem=strict via ReadWritePaths, kept
      # across restarts and reboots — and the path is handed to every
      # job as $CI_CACHE_DIR, so a workflow's CARGO_TARGET_DIR lives on
      # this disk instead of /var/cache. One instance per project is
      # what makes this pay: its cache only ever holds that project's
      # artifacts, so it stays warm and never needs clearing.
      storageRoot ? null,
      # Linux scheduling priority. Higher (less eager) than default so audio
      # / interactive work on this DAW workstation pre-empts the runner.
      nice ? 10,
      # CPU/IO cgroup weights (1..10000, default 100). Halved so the runner
      # yields gracefully under contention.
      cpuWeight ? 50,
      ioWeight ? 50,
      ...
    }:
    {
      # One aspect per runner (a host may run several).
      name = "github-runner(${name})";
      description = ''
        GitHub Actions self-hosted runner registered against ${url}.

        Runs org CI jobs (image build + push) directly on this host via the
        nixpkgs services.github-runners module. Static `github-runner` user;
        token (fine-grained PAT or registration token) read from sops.
      '';

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          indices = lib.range 1 count;
          # A single instance keeps the bare name, so an existing
          # deployment's registration and work tree are not orphaned by
          # merely gaining this option.
          instanceName = i: if count == 1 then name else "${name}-${toString i}";
          ciDir = instance: "${storageRoot}/ci/${instance}";
          onDisk = storageRoot != null;
        in
        {
          # Static user so the sops-owned token can be chowned at activation
          # (the module defaults to DynamicUser, which can't own a file
          # pre-created by sops-install-secrets). Home under /var/lib so nix
          # flake eval has a writable HOME/XDG base.
          users.users.github-runner = {
            isSystemUser = true;
            group = "github-runner";
            description = "GitHub Actions runner";
            home = "/var/lib/github-runner";
          };
          users.groups.github-runner = { };

          # Runner token. SOPS-encrypted, consumed RAW by the module's
          # `tokenFile`. A fine-grained PAT is created into a registration
          # token on each start; a registration token is used directly.
          # Every instance restarts when the token rotates.
          sops.secrets.${tokenKey} = {
            sopsFile = lib.mkIf (tokenSopsFile != null) tokenSopsFile;
            owner = "github-runner";
            group = "github-runner";
            mode = "0400";
            restartUnits = map (i: "github-runner-${instanceName i}.service") indices;
          };

          # Work roots — checkouts only; the module empties these on every
          # start. `d` (not `D`) so a rebuild does not race a running job.
          systemd.tmpfiles.rules = lib.optionals (!onDisk) (
            [ "d ${workRoot} 0700 github-runner github-runner - -" ]
            ++ map (i: "d ${workRoot}/${instanceName i} 0700 github-runner github-runner - -") indices
          );

          # On a chosen disk the directories are made at activation, not by
          # tmpfiles: tmpfiles refuses an "unsafe path transition" — a
          # parent owned by a person (the mount, owned by cody) with a
          # child owned by another user — and silently creates nothing
          # under it. The units then fail at namespace setup, because
          # ReadWritePaths must exist before ExecStartPre runs. Activation
          # runs as root, ahead of the units, and has no such policy.
          system.activationScripts."github-runner-dirs-${name}" = lib.mkIf onDisk (
            lib.stringAfter [ "users" "groups" ] (
              lib.concatMapStringsSep "\n" (i: ''
                install -d -m 0700 -o github-runner -g github-runner \
                  ${workRoot}/${instanceName i} ${ciDir (instanceName i)}
              '') indices
              + ''
                chown github-runner:github-runner ${workRoot} ${storageRoot}/ci
                chmod 0755 ${workRoot} ${storageRoot}/ci
              ''
            )
          );

          services.github-runners = lib.genAttrs (map instanceName indices) (instance: {
            enable = true;
            inherit url;
            name = instance;
            # Static user/group -> module forces DynamicUser=false.
            user = "github-runner";
            group = "github-runner";
            # Point straight at the sops secret (raw token file).
            tokenFile = config.sops.secrets.${tokenKey}.path;
            extraLabels = labels;
            # The checkout, on disk rather than in tmpfs. Emptied by the
            # module on every start — the durable half is CacheDirectory
            # below, which is where CARGO_TARGET_DIR belongs.
            workDir = "${workRoot}/${instance}";
            # Re-register when config (url/name/labels/token) changes.
            replace = true;
            # Non-ephemeral: persist the runner across jobs (default).
            ephemeral = false;
            # Workflow `run:` tooling. The module already puts
            # bashInteractive, coreutils, git, gnutar, gzip and
            # config.nix.package (nix) on PATH; add the rest deploy.yml needs.
            # skopeo is normally fetched via `nix run nixpkgs#skopeo` (hence
            # nix is the critical one) but is added here as a fallback.
            extraPackages = with pkgs; [
              curl
              gawk
              gnused
              nodejs
              skopeo
            ];
            # Yield to interactive/audio work on this DAW workstation. Same
            # rationale as the forgejo-runner aspect — with several
            # instances this matters more, not less: the weights are what
            # keep a full workspace rebuild from being audible.
            serviceOverrides = {
              Nice = nice;
              CPUWeight = cpuWeight;
              IOWeight = ioWeight;
              # The durable build cache: /var/cache/<cacheRoot>/<instance>,
              # created and kept by systemd across restarts and reboots, and
              # writable despite ProtectSystem=strict. Workflows point
              # CARGO_TARGET_DIR here; nothing else on the unit removes it.
              CacheDirectory = "${cacheRoot}/${instance}";
              CacheDirectoryMode = "0700";
            }
            // lib.optionalAttrs onDisk {
              # The same cache on the big disk instead. Jobs read it as
              # $CI_CACHE_DIR (the runner hands its environment to every
              # step), so a workflow never has to know the host's layout.
              ReadWritePaths = [ (ciDir instance) ];
              Environment = [ "CI_CACHE_DIR=${ciDir instance}" ];
            };
          });
        };
    };
}
