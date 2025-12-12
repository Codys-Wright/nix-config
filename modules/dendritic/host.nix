# Parametric provider for host configuration
# Sets hostname for nixos and darwin systems
{
  den,
  FTS,
  ...
}:
{
  den.aspects.dendritic.provides.host =
    { host, ... }:
    { class, ... }:
    {
      # Only set hostName for OS classes (nixos/darwin), not homeManager
      nixos.networking.hostName = host.hostName;
      darwin.networking.hostName = host.hostName;
    };
}

