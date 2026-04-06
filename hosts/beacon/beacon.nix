{
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux.beacon = {
    description = "Universal installation beacon ISO";
    aspect = "beacon-aspect";
    includes = [ ]; # skip home-manager defaults for ISO
  };

  den.aspects.beacon-aspect = {
    includes = [
      <fleet/fonts>
      <fleet/phoenix>
      <fleet/beacon>
      (fleet.deploy {
        ip = "192.168.0.100";
        sshUser = "installer";
      })
    ];
  };
}
