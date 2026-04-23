{
  lib,
  den,
  fleet,
  __findFile,
  ...
}:
let

  description = ''
    Sets a user's preferred terminal and TERM environment variable.

    Usage:

      den.aspects.vic.includes = [
        (fleet.coding._.user-terminal "kitty")
      ];
  '';

  userTerminal =
    terminal: from:
    let
      os =
        { lib, ... }:
        {
          environment.variables.TERMINAL = lib.mkForce terminal;
        };
      homeManager =
        { lib, ... }:
        {
          home.sessionVariables.TERMINAL = lib.mkForce terminal;
        };
    in
    {
      inherit os homeManager;
    };

in
{
  fleet.coding._.user-terminal =
    terminal:
    <den.lib.parametric> {
      inherit description;
      includes = [
        ({ user, ... }: userTerminal terminal user)
        ({ home, ... }: userTerminal terminal home)
      ];
    };
}
