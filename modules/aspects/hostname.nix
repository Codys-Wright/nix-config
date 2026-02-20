{
  FTS,
  ...
}:
{
  # Minimal host naming aspect; den provides host context.
  FTS.hostname =
    { host, ... }:
    {
      nixos.networking.hostName = host.hostName;
      darwin.networking.hostName = host.hostName;
    };
}
