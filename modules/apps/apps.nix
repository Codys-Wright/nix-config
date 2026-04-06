# Apps aggregator
# Usage: <fleet/apps>
{
  fleet,
  __findFile,
  ...
}:
{
  fleet.apps = {
    description = "All user applications";

    includes = [
      <fleet.apps/browsers>
      <fleet.apps/communications>
      <fleet.apps._.notes/obsidian>
      <fleet.apps._.recording/obs>
      <fleet.apps/flatpaks>
      <fleet.apps/misc>
      <fleet.apps._.ai/openclaw>
    ];
  };
}
