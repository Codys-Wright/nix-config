# One shared CPU budget for every CI runner on THEBATTLESHIP.
#
# Each runner instance (github-runner-*, gitea-runner-*) and every job it
# spawns runs inside ci.slice, so the cap below holds for all of them
# together, however many build at once. CPUQuota is a share of the whole
# box: 32 threads = 3200%, so 1600% leaves half the CPU for cody's own work
# and the agents.
#
# Added 2026-11-15 after the hard resets: full-box CI builds plus agent
# builds were the load in effect when the machine reset (suspected PSU
# tripping on power spikes). Raise the quota once the PSU question is settled.
{ ... }:
{
  den.aspects.THEBATTLESHIP-ci-slice = {
    description = "Shared CPU budget (ci.slice) for all CI runners on THEBATTLESHIP";

    nixos =
      { config, lib, ... }:
      let
        githubUnits = map (n: "github-runner-${n}") (lib.attrNames (config.services.github-runners or { }));
        # The Codeberg runners (fleet.ci._.forgejo-runner in THEBATTLESHIP.nix).
        # Their docker:// jobs run in Docker's own cgroups, so the slice only
        # caps the runner itself and its host-mode (nix-host) jobs.
        giteaUnits = [
          "gitea-runner-codeberg"
          "gitea-runner-codeberg-org"
        ];
      in
      {
        systemd.slices.ci = {
          description = "CI runners (shared CPU budget)";
          sliceConfig.CPUQuota = "1600%";
        };

        systemd.services = lib.genAttrs (githubUnits ++ giteaUnits) (_: {
          serviceConfig.Slice = "ci.slice";
        });
      };
  };
}
