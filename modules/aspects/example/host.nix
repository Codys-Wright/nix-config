# parametric providers for host
{
  den,
  FTS,
  ...
}:
{
  den.aspects.example.provides.host =
    { host, ... }:
    { class, ... }:
    {
      # # `_` is a shorthand alias for `provides`
      # includes = [ FTS.example._.vm-bootable ];
      # Only set hostName for OS classes (nixos/darwin), not homeManager
      nixos.networking.hostName = host.hostName;
      darwin.networking.hostName = host.hostName;
    };
}

