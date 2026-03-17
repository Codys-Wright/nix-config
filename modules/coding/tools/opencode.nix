# OpenCode AI terminal assistant aspect
{
  FTS,
  ...
}:
{
  FTS.coding._.tools._.opencode = {
    description = "OpenCode AI terminal assistant";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          opencode
          claude-code

          # amazon-q-cli
          # aider-chat
          # codex
          # copilot-cli
          # crush
          # cursor-cli
          # gemini-cli
          # qwen-code
        ];
      };
  };
}
