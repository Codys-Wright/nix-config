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
      envVars = {
        TERMINAL = terminal;
        TERM = "xterm-256color"; # Default TERM value, can be overridden if needed
      };
      os =
        { ... }:
        {
          environment.sessionVariables = envVars;
        };
      homeManager =
        { ... }:
        {
          home.sessionVariables = envVars;
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
