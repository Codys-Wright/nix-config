# Docker tools aspect
{
  FTS, ... }:
{
  FTS.coding._.tools._.docker = {
    description = "Docker and container tools";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          docker
          docker-compose
          lazydocker
        ];
      };
  };
}

