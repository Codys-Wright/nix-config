{
  FTS,
  __findFile,
  ...
}:
{
  FTS.base-host = {
    description = "Base host defaults shared by all hosts";

    includes = [
      <FTS/nh>
      <FTS/system>
    ];
  };
}
