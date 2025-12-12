# System facet - Essential system configuration
{
  FTS,
  ...
}:
{
  FTS.system = {
    description = ''
      System configuration facet.
      Includes essential system utilities, SSH, and networking.
    '';

    includes = [
      FTS.system._.utils      # Essential system utilities (vim, curl, git, etc.)
      FTS.system._.ssh        # SSH server with secure defaults
      FTS.system._.networking # Basic networking (systemd-networkd with DHCP)
      # FTS.system._.disk is used separately as parametric: (<FTS.system/disk> { ... })
    ];
  };
}
