# Gaming platforms aggregator
# Usage: <FTS/gaming>
{
  FTS,
  __findFile,
  ...
}:
{
  FTS.gaming = {
    description = "All gaming platforms and tools";

    includes = [
      <FTS.gaming/steam>
      <FTS.gaming/minecraft>
      <FTS.gaming/lutris>
      <FTS.gaming/bottles>
      <FTS.gaming/winboat>
      <FTS.gaming/proton>
      <FTS.gaming/melonloader>
      <FTS.gaming/r2modman>
    ];
  };
}
