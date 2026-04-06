# Helper for aspects to add groups to all host users.
#
# Usage in any FTS aspect included by a host:
#   includes = [ (den.lib.groups [ "libvirtd" "docker" ]) ];
#
# Uses host context: silently skipped when no host context (e.g. standalone homes).
{ den, ... }:
{
  den.lib.groups =
    groups:
    { host, ... }:
    {
      nixos =
        { lib, ... }:
        lib.mkMerge (
          map (userName: {
            users.users.${userName}.extraGroups = groups;
          }) (builtins.attrNames host.users)
        );
    };
}
