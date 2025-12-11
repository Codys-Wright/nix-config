# Coding meta-aspect - includes all coding-related modules
{
  FTS, ... }:
{
  FTS.coding = {
    description = "All coding modules - includes cli-tools, editors, lang, shell-tools, terminals, and tools";

    includes = [
      FTS.cli-tools
      FTS.editors
      FTS.lang
      FTS.shells
      (FTS.coding._.terminals { })  # Include all terminals with ghostty as default
      FTS.tools
    ];
  };
}

