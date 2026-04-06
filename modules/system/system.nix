# System facet - Essential system configuration
{
  fleet,
  ...
}:
{
  fleet.system = {
    description = ''
      System configuration facet.
      Includes essential system utilities, SSH, and networking.
    '';

    includes = [
      fleet.system._.utils # Essential system utilities (vim, curl, git, etc.)
      fleet.system._.ssh # SSH server with secure defaults
      fleet.system._.networking # Basic networking (systemd-networkd with DHCP)
      # fleet.system._.disk is used separately as parametric: (<fleet.system/disk> { ... })
    ];
  };
}
