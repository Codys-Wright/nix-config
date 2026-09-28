# Unix group membership from any aspect, wherever it is included.
#
#   (<fleet.user/groups> [ "video" ])         every user the aspect reaches
#   (<fleet.user/admin-groups> [ "docker" ])  only users with <fleet.user/admin>
#
# Den delivers the `user` class (→ users.users.<name>) only from user scope,
# so each helper emits both edges:
#   - included by a USER aspect → the `user` class lands on that user alone
#   - included by a HOST aspect → `provides.to-users` reaches every user on it
# (docs: den explanation/where-config-lands, "Add users to groups".)
#
# Root-equivalent groups (docker, libvirtd, the podman socket) go through
# admin-groups so co-op / guest / child accounts never get them.
#
# NixOS only: nix-darwin's users.users has no extraGroups, and the `user`
# class routes into whatever the host's class is. `host.class` is static
# entity data, so branching on it at the aspect level is safe.
{ fleet, lib, ... }:
let
  label = kind: groups: "${kind}(${lib.concatStringsSep "," groups})";

  onNixos =
    host: userModule: lib.optionalAttrs ((host.class or null) == "nixos") { user = userModule; };

  # Class-module body, so hasAspect reads the frozen tree (cycle-safe).
  adminOnly =
    groups: user:
    { lib, ... }:
    {
      extraGroups = lib.mkIf (user.hasAspect fleet.user._.admin) groups;
    };

  mkGroups = kind: userModuleFor: groups: {
    name = label kind groups;
    includes = [ ({ host, user, ... }: onNixos host (userModuleFor groups user)) ];
    provides.to-users = { host, user, ... }: onNixos host (userModuleFor groups user);
  };
in
{
  fleet.user._.groups.__functor =
    _self: groups:
    mkGroups "groups" (groups: _user: { extraGroups = groups; }) groups
    // {
      description = "Adds the users it reaches to: ${lib.concatStringsSep ", " groups}";
    };

  fleet.user._.admin-groups.__functor =
    _self: groups:
    mkGroups "admin-groups" adminOnly groups
    // {
      description = "Adds admin users (those with <fleet.user/admin>) to: ${lib.concatStringsSep ", " groups}";
    };
}
