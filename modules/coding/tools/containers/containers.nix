# Container tools facet - Podman and related tools
{FTS, ...}: {
  FTS.coding._.tools._.containers = {
    description = "Container tools - Podman with Docker compatibility";

    includes = [
      FTS.coding._.tools._.containers._.podman
    ];
  };
}
