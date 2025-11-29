{ lib, den, ... }:
let
  # Map common terminal names to their TERM values
  defaultTermMap = {
    kitty = "xterm-kitty";
    alacritty = "alacritty";
    foot = "foot";
    wezterm = "wezterm";
    gnome-terminal = "gnome";
    xterm = "xterm-256color";
    rxvt-unicode = "rxvt-unicode-256color";
    st = "st-256color";
    tmux = "tmux-256color";
    screen = "screen-256color";
  };

  # Parse terminal argument - can be a string or an attrset
  parseTerminal = arg:
    if lib.isString arg then
      {
        terminal = arg;
        term = defaultTermMap.${arg} or "xterm-256color";
      }
    else if lib.isAttrs arg then
      {
        terminal = arg.terminal or (throw "user-terminal: 'terminal' field is required");
        term = arg.term or (defaultTermMap.${arg.terminal} or "xterm-256color");
      }
    else
      throw "user-terminal: argument must be a string or an attribute set";
in
{
  den.provides.user-terminal.description = ''
    Sets a user's preferred terminal and TERM environment variable.

    Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

    ## Usage

      den.aspects.vic.includes = [
        (den._.user-terminal "kitty")
        # or with custom TERM value
        (den._.user-terminal { terminal = "kitty"; term = "xterm-kitty"; })
      ];

    It will dynamically provide a module for each class when accessed.
  '';

  den.provides.user-terminal.__functor =
    _self: arg:
    { class, aspect-chain }:
    let
      terminalConfig = parseTerminal arg;
      terminal = terminalConfig.terminal;
      term = terminalConfig.term;
      
      # Set environment variables based on class
      envVars = {
        TERMINAL = terminal;
        TERM = term;
      };
      
      config = if class == "nixos" then
        { environment.sessionVariables = envVars; }
      else if class == "darwin" then
        { environment.variables = envVars; }
      else if class == "homeManager" then
        { home.sessionVariables = envVars; }
      else
        { };
    in
    den.lib.take.unused aspect-chain {
      ${class} = config;
    };
}

