# This example implements an aspect "routing" pattern.
#
# Unlike `den.default` which is `parametric.atLeast`
# we use `parametric.fixedTo` here, which help us
# propagate an already computed context to all includes.
#
# This aspect, when installed in a `parametric.atLeast`
# will just forward the same context.
# The `mutual` helper returns an static configuration which
# is ignored by parametric aspects, thus allowing
# non-existing aspects to be just ignored.
#
# Be sure to read: https://vic.github.io/den/dependencies.html
# See usage at: defaults.nix, alice.nix, igloo.nix
#
{ den, ... }:
{
  # Usage: `den.default.includes [ den.aspects.example._.routes ]`
  den.aspects.example.provides.routes =
    let
      inherit (den.lib) parametric;

      # example, `<user>._.<host>` and `<host>._.<user>`
      mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { };

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
