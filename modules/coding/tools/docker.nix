# Docker tools aspect
{
  FTS, ... }:
{
  FTS.docker = {
    description = "Docker and container tools";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenvNoCC.isDarwin {
        home.packages = with pkgs; [
          docker
          docker-compose
          lazydocker
        ];
      };
  };
}

