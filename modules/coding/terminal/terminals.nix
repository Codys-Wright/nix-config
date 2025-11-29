# Terminals meta-aspect - includes all terminal modules
# Can optionally take a parameter to set the default terminal via user-terminal
{ den, lib,
  FTS, ... }:
let
  baseIncludes = [
    FTS.ghostty
    FTS.kitty
    FTS.tmux
  ];
  
  # Extract terminal name from attribute set
  getTerminal = arg:
    if arg == null || arg == { } then
      null
    else if lib.isAttrs arg then
      arg.default or arg.terminal or (throw "terminals: 'default' or 'terminal' field is required")
    else
      throw "terminals: argument must be an attribute set with 'default' or 'terminal' field";
in
{
  FTS.terminals = {
    description = ''
      All terminal modules (ghostty, kitty, tmux).
      
      Can optionally take a terminal name to set as default:
        FTS.dave.includes = [ (FTS.terminals { default = "ghostty"; }) ];
      
      Or use without parameter to just include all terminals:
        FTS.dave.includes = [ FTS.terminals ];
    '';

    includes = baseIncludes;

    # Make it work as a parametric provider when called with a terminal name
    # This internally uses user-terminal to set the TERMINAL and TERM environment variables
    __functor = self: arg:
      let
        terminal = getTerminal arg;
      in
      if terminal == null then
        # No parameter - just return the base aspect
        self
      else
        # Parameter provided - add user-terminal to set the default terminal
        # Preserve all attributes from self and update includes
        {
          inherit (self) description;
          includes = baseIncludes ++ [ (den._.user-terminal terminal) ];
        };
  };
}

