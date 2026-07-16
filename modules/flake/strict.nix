# Den strict mode, selectively applied.
#
# Upstream `inputs.den.flakeModules.strict` makes every den.schema.* freeform
# type throw on undeclared keys — including `aspect`, where the class keys
# (nixos / darwin / homeManager / os / user / includes / provides / meta …)
# are dynamic by design; strict-ing aspects would mean re-declaring den's own
# surface. So we apply the strict freeform only to the entity kinds where an
# undeclared key is almost certainly a typo: host, user, home, and flake
# entries. Every legitimate custom key must be declared in
# modules/flake/schema-options.nix — declare the option, never delete data.
{ den, ... }:
{
  den.schema.host = den.lib.strict;
  den.schema.user = den.lib.strict;
  den.schema.home = den.lib.strict;
  den.schema.flake = den.lib.strict;
}
