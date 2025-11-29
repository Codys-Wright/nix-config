# Shell meta-aspect - includes all shell modules
# Can optionally take a parameter to set the default shell via user-shell
{ den, lib,
  FTS, ... }:
let
  description = ''
    All shell modules (zsh, fish, starship, powerlevel10k).

    Can optionally take a shell name to set as default:
      FTS.dave.includes = [ (FTS.shell { default = "zsh"; }) ];

    Or use without parameter to just include all shell modules:
      FTS.dave.includes = [ FTS.shell ];
  '';

  baseIncludes = [
    FTS.zsh
    FTS.fish
    FTS.starship
    FTS.powerlevel10k
  ];
in
{
  FTS.shell = den.lib.parametric {
    inherit description;
    includes = baseIncludes ++ [
      ({ user, home, ... }: arg:
        let
          # Extract shell name from argument if provided
          shell = if arg == null || arg == { } then
            null
          else if lib.isAttrs arg then
            arg.default or arg.shell or (throw "shell: 'default' or 'shell' field is required")
          else
            throw "shell: argument must be an attribute set with 'default' or 'shell' field";
        in
        if shell == null then
          # No parameter provided - just return empty (base includes already added above)
          { }
        else
          # Parameter provided - add user-shell to set the default shell
          den._.user-shell shell
      )
    ];
  };
}
