{ __findFile, ... }:
{
  # No users: an installer ISO, so no home-manager and no user defaults.
  den.hosts.x86_64-linux.beacon = {
    description = "Universal installation beacon ISO";
    deployment = {
      ip = "192.168.0.100";
      sshUser = "installer";
    };
  };

  den.aspects.beacon.includes = [
    <fleet/fonts>
    <fleet/phoenix>
    <fleet/beacon>
  ];
}
