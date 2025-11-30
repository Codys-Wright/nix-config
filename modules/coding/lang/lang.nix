# Language tools meta-aspect - includes all language modules
{
  FTS, ... }:
{
  FTS.lang = {
    description = "All language modules - includes rust and typescript";

    includes = [
      FTS.rust
      FTS.typescript
    ];
  };
}

