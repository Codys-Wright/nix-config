# CLI tools meta-aspect - includes all CLI tool modules
{
  FTS, ... }:
{
  FTS.keyboard = {
    description = "Keyboard Configuration";

    includes = [
      FTS.kanata
      FTS.karabiner-elements
    ];
    
  };
}

