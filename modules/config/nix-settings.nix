{
  fleet,
  den,
  __findFile,
  ...
}:
let
  nixSettings =
    { config, lib, ... }:
    {
      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            # NOTE: lazy-trees is Determinate-Nix-only (not upstream Nix). If you
            # ever switch nix.package to inputs.determinate, add "lazy-trees" here
            # for big wins on dirty-tree evals.
          ];
          trusted-users = [
            "root"
            "@wheel"
            "@admin"
          ];
          substituters = [
            "https://cache.nixos.org/"
            "https://fasttrackstudio.cachix.org"
            "https://microvm.cachix.org"
            "https://fleet.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "fasttrackstudio.cachix.org-1:r7v7WXBeSZ7m5meL6w0wttnvsOltRvTpXeVNItcy9f4="
            "microvm.cachix.org-1:oXnAttsRgXtB2wXwwITVq3+NzJIhWQz9MKPAF8FcVPs="
            "fleet.cachix.org-1:OXtbUqSc/c0fVhiq9pBAmb/4eGVcfz7qlNWFmvQpNj8="
          ];
        };
        gc = lib.optionalAttrs config.nix.enable {
          automatic = true;
          options = "--delete-older-than 7d";
        };
      };
    };
in
{
  fleet.nix-settings = {
    description = "Shared nix settings and package policy";
    includes = [
      <fleet/nix>
    ];
    os = nixSettings;

    # NixOS-only (darwin has no systemd).
    nixos =
      { config, lib, ... }:
      {
        # crates.io answers 403 to any User-Agent shaped like
        # `curl/<version>`, and nixpkgs' fetchurl introduces itself as
        # "curl/8.18.0 Nixpkgs/26.11". Every crate tarball not already in
        # the store therefore fails to download:
        #
        #   trying https://crates.io/api/v1/crates/toml_edit/0.25.3+.../download
        #   curl: (22) The requested URL returned error: 403
        #   error: cannot download crate-toml_edit-... from any mirror
        #
        # It hits anything vendoring crates through nix — importCargoLock,
        # crane, fetchCrate — and it reads like a dependency problem in
        # whatever happened to be building. It is what actually stopped
        # THEBATTLESHIP rebuilding (via fts-rigs → reaper-launcher).
        #
        # Dropping the version is enough; bare "Nixpkgs" is accepted.
        # fetchurl declares NIX_CURL_FLAGS impure precisely so a host can
        # do this. Remove once nixpkgs stops sending a `curl/` UA.
        systemd.services.nix-daemon.environment.NIX_CURL_FLAGS =
          lib.mkIf config.nix.enable "--user-agent Nixpkgs";

        # Builds never take the machine down. electric (32 GB, no swap) ran a
        # full rebuild out of memory: the OOM killer took plasmashell and the
        # Loft shell, the box crawled until it was power-cycled. Builds now
        # leave 2 CPUs and 4 GiB of RAM to everything else (a runaway build
        # is killed inside the daemon's cgroup, the desktop untouched), and
        # yield to interactive work.
        nix = lib.mkIf config.nix.enable {
          daemonCPUSchedPolicy = lib.mkDefault "batch";
          daemonIOSchedClass = lib.mkDefault "best-effort";
          daemonIOSchedPriority = lib.mkDefault 7;
        };
        # When memory runs out anyway, a build goes before the desktop.
        systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkIf config.nix.enable (
          lib.mkDefault 500
        );
        # The reserve depends on the host, and CPUQuota is absolute (100% =
        # one CPU), so it is computed at boot. Bytes, not percentages: a
        # MemoryHigh=N% set-property lands in 50-MemoryHighScale.conf, which
        # sorts after (and silently beats) 50-MemoryHigh.conf.
        systemd.services.nix-daemon-limits = lib.mkIf config.nix.enable {
          description = "Leave 2 CPUs and 4 GiB of RAM free of nix builds";
          wantedBy = [ "multi-user.target" ];
          before = [ "nix-daemon.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            gib=$((1024 * 1024 * 1024))
            cpus=$(nproc)
            mem=$(( $(sed -n 's/^MemTotal: *\([0-9]*\) kB/\1/p' /proc/meminfo) * 1024 ))
            quota=$(( cpus > 3 ? (cpus - 2) * 100 : 100 ))
            max=$(( mem - 4 * gib ))
            # Small hosts: never squeeze builds below half the RAM.
            [ "$max" -lt $(( mem / 2 )) ] && max=$(( mem / 2 ))
            high=$(( max - gib ))
            systemctl set-property --runtime nix-daemon.service \
              CPUQuota=''${quota}% MemoryHigh=$high MemoryMax=$max
            echo "nix builds: CPUQuota=''${quota}% MemoryHigh=$high MemoryMax=$max"
          '';
        };
        # Root's builds bypass the daemon by default: `nix-daemon --stdio`
        # under deploy-rs --remote-build, nixos-rebuild, nix-store -r over SSH
        # all open the store directly, in the SSH session's cgroup, outside
        # the limits above. Send them through the daemon instead (PAM session
        # environment, so SSH commands get it too).
        environment.sessionVariables.NIX_REMOTE = lib.mkIf config.nix.enable "daemon";
      };
  };
}
