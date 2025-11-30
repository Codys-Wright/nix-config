# Browsers meta-aspect - includes all browser modules
# Can optionally take a parameter to set the default browser via user-browser
{ den, lib, FTS, ... }:
let
  description = ''
    All browser modules (zen, brave, firefox).
    
    Can optionally take a browser name to set as default:
      FTS.dave.includes = [ (FTS.browsers { default = "firefox"; }) ];
      FTS.dave.includes = [ (FTS.browsers "firefox") ];
    
    Or use without parameter to just include all browsers:
      FTS.dave.includes = [ FTS.browsers ];
  '';

  baseIncludes = [
    FTS.zen-browser
    FTS.brave
    FTS.firefox
  ];
  
  # Extract browser name from argument
  getBrowser = arg:
    if arg == null || arg == { } then
      null
    else if lib.isString arg then
      arg
    else if lib.isAttrs arg then
      arg.default or arg.browser or (throw "browsers: 'default' or 'browser' field is required")
    else
      throw "browsers: argument must be a string, attribute set with 'default' or 'browser' field, or null";
in
{
  FTS.browsers = den.lib.parametric {
    inherit description;
    includes = baseIncludes ++ [
      ({ user, home, ... }: arg:
        let
          browser = getBrowser arg;
        in
        if browser == null then
          # No parameter provided - just return empty (base includes already added above)
          { }
        else
          # Parameter provided - include user-browser to set the default browser
          (den._.user-browser browser)
      )
    ];
  };
}

