# parametric providers for host
{
  den,
  FTS,
  ...
}:
{
  FTS.example.provides.host =
    { host }:
    { class, ... }:
    {
      # `_` is a shorthand alias for `provides`
      includes = [ FTS.example._.vm-bootable ];
      ${class}.networking.hostName = host.hostName;
    };
}

