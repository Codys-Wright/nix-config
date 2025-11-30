# Tools meta-aspect - includes all tool modules
{
  FTS, ... }:
{
  FTS.tools = {
    description = "All tool modules - includes docker, git, lazygit, opencode, and dev-tools";

    includes = [
      FTS.docker
      FTS.git
      FTS.lazygit
      FTS.opencode
      FTS.dev-tools
    ];
  };
}

