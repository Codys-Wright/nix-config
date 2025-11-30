# LazyGit configuration aspect
{
  FTS, ... }:
{
  FTS.lazygit = {
    description = "LazyGit terminal UI for git";

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.lazygit = {
          enable = true;
          settings = lib.mkForce {
            gui = {
              theme = {
                activeBorderColor = [
                  "#007acc" # Use your accent color
                  "bold"
                ];
                inactiveBorderColor = [ "#666666" ];
              };
              showListFooter = false;
              showRandomTip = false;
              showCommandLog = false;
              showBottomLine = false;
              nerdFontsVersion = "3";
            };
          };
        };
      };
  };
}

