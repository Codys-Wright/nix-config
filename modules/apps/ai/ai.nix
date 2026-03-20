# AI tools facet
{ FTS, ... }:
{
  FTS.apps._.ai = {
    description = "AI assistant tools";

    includes = [
      FTS.apps._.ai._.openclaw
    ];
  };
}
