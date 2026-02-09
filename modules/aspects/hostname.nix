{
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.hostname = den.lib.parametric {
    description = "Set hostname from den host context";

    includes = [
      (
        { host, ... }:
        {
          ${host.class}.networking.hostName = lib.mkDefault (host.hostName or host.name);
        }
      )
    ];
  };
}
