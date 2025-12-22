# Tools facet - All development tools
{
  FTS,
  ...
}:
{
  FTS.coding._.tools = {
    description = "All development tools - containers, git, lazygit, opencode, dev-tools";

    includes = [
      FTS.coding._.tools._.containers._.podman
      FTS.coding._.tools._.git
      FTS.coding._.tools._.lazygit
      FTS.coding._.tools._.opencode
      FTS.coding._.tools._.dev-tools
    ];
  };
}

