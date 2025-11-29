# OpenCode AI terminal assistant aspect
{
  FTS, ... }:
{
  FTS.opencode = {
    description = "OpenCode AI terminal assistant";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenvNoCC.isDarwin {
        home.packages = with pkgs; [
          opencode
        ];
      };
  };
}

