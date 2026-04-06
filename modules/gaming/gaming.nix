# Gaming platforms aggregator
# Usage: <fleet/gaming>
{
  fleet,
  __findFile,
  ...
}:
{
  fleet.gaming = {
    description = "All gaming platforms and tools";

    includes = [
      <fleet.gaming/steam>
      <fleet.gaming/minecraft>
      <fleet.gaming/lutris>
      <fleet.gaming/bottles>
      <fleet.gaming/winboat>
      <fleet.gaming/proton>
      <fleet.gaming/melonloader>
      <fleet.gaming/r2modman>
    ];
  };
}
