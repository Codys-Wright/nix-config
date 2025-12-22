# Docker tools aspect (legacy - prefer podman)
{
  FTS, ... }:
{
  FTS.coding._.tools._.containers._.docker = {
    description = "Docker container tools (legacy - prefer podman)";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          lazydocker
        ];
      };
  };
}

