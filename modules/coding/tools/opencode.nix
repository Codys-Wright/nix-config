# OpenCode AI terminal assistant aspect
{
  FTS, ... }:
{
  FTS.opencode = {
    description = "OpenCode AI terminal assistant";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          opencode
        ];
      };
  };
}

