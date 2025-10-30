# Git configuration aspect
{ ... }:
{
  den.aspects.git = {
    description = "Git version control with delta and LFS support";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenvNoCC.isDarwin {
        programs.git = {
          enable = true;
          settings = {
            user = {
              name = "Cody Wright";
              email = "acodywright@gmail.com";
            };
          };
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

