# Restricted accounts (children, kiosks) opt out of the per-user halves that
# host-included features hand to every user of the host.
#
#   den.aspects.joshua.includes = [ <fleet.user/restricted> ];
#   fleet.some-feature.provides.to-users.includes = [
#     (<fleet.user/unless-restricted> <fleet.some-feature/user-half>)
#   ];
#
# `excludes` can't do this: it only covers the excluding aspect's own subtree,
# while to-users content arrives from the host. A policy guard reads the
# user's resolved tree (structural hasAspect is safe in guards).
{ den, fleet, ... }:
{
  fleet.user._.restricted = {
    description = "Marker: restricted account — skipped by host features' per-user halves";
  };

  fleet.user._.unless-restricted.__functor =
    _self: aspect:
    den.lib.policy.when ({ user, ... }: !(user.hasAspect fleet.user._.restricted)) {
      includes = [ aspect ];
    };
}
