# Tools facet - All development tools
{
  FTS,
  ...
}:
{
  FTS.coding._.tools = {
    description = "All development tools - docker, git, lazygit, opencode, dev-tools";
    
    includes = [
      FTS.coding._.tools._.docker
      FTS.coding._.tools._.git
      FTS.coding._.tools._.lazygit
      FTS.coding._.tools._.opencode
      FTS.coding._.tools._.dev-tools
    ];
  };
}

