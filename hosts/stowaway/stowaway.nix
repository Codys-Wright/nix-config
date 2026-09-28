{ __findFile, ... }:
{
  den.hosts.x86_64-linux.stowaway = {
    description = "MacBookPro15,1 (T2) — covert field unit, dual-booted with macOS";
    users.cody = { };
    timeZone = "America/Los_Angeles";
    deployment.ip = "192.168.0.139";
  };

  den.aspects.stowaway.includes = [ <fleet.roles/t2-laptop> ];
}
