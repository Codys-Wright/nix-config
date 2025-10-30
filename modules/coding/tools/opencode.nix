# OpenCode AI terminal assistant aspect
{ ... }:
{
  den.aspects.opencode = {
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

