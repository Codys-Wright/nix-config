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
