{
  lib,
  den,
  FTS,
  __findFile,
  ...
}:
let

  description = ''
    Sets a user's preferred terminal and TERM environment variable.

    Usage:

      den.aspects.vic.includes = [
        (FTS.coding._.user-terminal "kitty")
      ];
  '';

  userTerminal =
    terminal: from:
    let
      envVars = {
        TERMINAL = terminal;
        TERM = "xterm-256color"; # Default TERM value, can be overridden if needed
      };
      nixos =
        { ... }:
        {
          environment.sessionVariables = envVars;
        };
      darwin = nixos;
      homeManager =
        { ... }:
        {
          home.sessionVariables = envVars;
        };
    in
    {
      inherit nixos darwin homeManager;
    };

in
{
  FTS.coding._.user-terminal =
    terminal:
    <den.lib.parametric> {
      inherit description;
      includes = [
        ({ user, ... }: userTerminal terminal user)
        ({ home, ... }: userTerminal terminal home)
      ];
    };
}
