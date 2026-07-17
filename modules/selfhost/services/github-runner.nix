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
  fleet.selfhost._.github-runner =
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
          sops.secrets.${tokenKey} = {
            sopsFile = lib.mkIf (tokenSopsFile != null) tokenSopsFile;
            owner = "github-runner";
            group = "github-runner";
            mode = "0400";
            restartUnits = [ "github-runner-${name}.service" ];
          };

          services.github-runners.${name} = {
            enable = true;
            inherit url name;
            # Static user/group -> module forces DynamicUser=false.
            user = "github-runner";
            group = "github-runner";
            # Point straight at the sops secret (raw token file).
            tokenFile = config.sops.secrets.${tokenKey}.path;
            extraLabels = labels;
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
            # rationale as the forgejo-runner aspect.
            serviceOverrides = {
              Nice = nice;
              CPUWeight = cpuWeight;
              IOWeight = ioWeight;
            };
          };
        };
    };
}
