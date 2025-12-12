# Routing pattern for mutual dependencies
#
# This implements an aspect "routing" pattern that allows
# aspects to reference each other mutually.
#
# Unlike `den.default` which is `parametric.atLeast`,
# we use `parametric.fixedTo` here, which helps us
# propagate an already computed context to all includes.
#
# This aspect, when installed in a `parametric.atLeast`
# will just forward the same context.
# The `mutual` helper returns a static configuration which
# is ignored by parametric aspects, thus allowing
# non-existing aspects to be just ignored.
#
# Be sure to read: https://vic.github.io/den/dependencies.html
#
{ den,
  FTS, ... }:
{
  # Usage: `den.default.includes [ den.aspects.dendritic._.routes ]`
  den.aspects.dendritic.provides.routes =
    let
      inherit (den.lib) parametric;

      # For example, `<user>._.<host>` and `<host>._.<user>`
      # Try to get mutual aspect, return empty if not found
      mutual = from: to: FTS.${from.aspect}._.${to.aspect} or { };

      routes =
        { host, user, ... }@ctx:
        parametric.fixedTo ctx {
          includes = [
            (mutual user host)
            (mutual host user)
          ];
        };
    in
    routes;
}

