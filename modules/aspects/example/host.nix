# parametric providers for host
{
  den,
  ...
}:
{
  den.aspects.example.provides.host =
    { host }:
    { class, ... }:
    {
      # `_` is a shorthand alias for `provides`
      includes = [ den.aspects.example._.vm-bootable ];
      ${class}.networking.hostName = host.hostName;
    };
}

