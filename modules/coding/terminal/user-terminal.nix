# A user's preferred terminal ($TERMINAL).
#
#   den.aspects.vic.includes = [ (<fleet.coding/user-terminal> "kitty") ];
{ lib, ... }:
{
  fleet.coding._.user-terminal.__functor = _self: terminal: {
    name = "user-terminal(${terminal})";
    description = "Sets $TERMINAL to ${terminal} for the user and on the hosts they live on";

    homeManager.home.sessionVariables.TERMINAL = lib.mkForce terminal;

    # System-wide too, so compositor-spawned processes (outside a login
    # shell) see it. One value per host — only the admin sets a terminal.
    provides.to-hosts.os.environment.variables.TERMINAL = lib.mkForce terminal;
  };
}
