# Docker tools aspect (legacy - prefer podman)
{ fleet, ... }:
{
  fleet.coding._.tools._.containers._.docker = {
    description = "Docker container tools (legacy - prefer podman)";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = with pkgs; [
          lazydocker
        ];
      };
  };
}
