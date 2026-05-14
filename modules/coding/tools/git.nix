# Git configuration aspect
{
  fleet,
  lib,
  ...
}:
{
  fleet.coding._.tools._.git = {
    description = "Git version control with delta and LFS support";

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.git = {
          enable = true;
          # User identity is set via fleet.git-identity — no hardcoded defaults
          lfs = {
            enable = true;
          };

          # Starcommand Forgejo is Cody's source-of-truth git host. Keep the
          # token in ~/.git-credentials (or the future SOPS-rendered equivalent),
          # but make every git invocation consistently look there instead of
          # prompting Codex/Claude sessions.
          settings = {
            credential = {
              helper = lib.mkForce "store --file ~/.git-credentials";
              "https://git.starcommand.live" = {
                username = "codywright";
                useHttpPath = false;
              };
            };
            url = {
              "https://git.starcommand.live/".insteadOf = [
                "forgejo:"
                "starcommand:"
              ];
            };
          };
        };

        programs.delta = {
          enable = true;
          enableGitIntegration = true;
          options = {
            line-numbers = true;
            side-by-side = true;
            navigate = true;
          };
        };

        home.packages = with pkgs; [
          git-lfs
          gh # GitHub CLI
          gitlab-runner
        ];
      };
  };
}
