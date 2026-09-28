{
  fleet,
  __findFile,
  ...
}:
{
  fleet.base-host = {
    description = "Base host defaults shared by all hosts";

    includes = [
      <fleet/nh>
      <fleet/system>
    ];
  };
}
