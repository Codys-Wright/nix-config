# Apps aggregator
# Usage: <FTS/apps>
{
  FTS,
  __findFile,
  ...
}:
{
  FTS.apps = {
    description = "All user applications";

    includes = [
      <FTS.apps/browsers>
      <FTS.apps/communications>
      <FTS.apps._.notes/obsidian>
      <FTS.apps._.recording/obs>
      <FTS.apps/flatpaks>
      <FTS.apps/misc>
      <FTS.apps._.ai/openclaw>
    ];
  };
}
