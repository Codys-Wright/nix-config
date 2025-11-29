# Browsers meta-aspect - includes all browser modules
# Can optionally take a parameter to set the default browser via user-browser
{ den, lib, FTS, ... }:
let
  baseIncludes = [
    FTS.zen-browser
    FTS.brave
    FTS.firefox
  ];
  
  # Extract browser name from attribute set
  getBrowser = arg:
    if arg == null || arg == { } then
      null
    else if lib.isAttrs arg then
      arg.default or arg.browser or (throw "browsers: 'default' or 'browser' field is required")
    else
      throw "browsers: argument must be an attribute set with 'default' or 'browser' field";
in
{
  FTS.browsers = {
    description = ''
      All browser modules (zen, brave, firefox).
      
      Can optionally take a browser name to set as default:
        FTS.dave.includes = [ (FTS.browsers { default = "firefox"; }) ];
      
      Or use without parameter to just include all browsers:
        FTS.dave.includes = [ FTS.browsers ];
    '';

    includes = baseIncludes;

    # Make it work as a parametric provider when called with a browser name
    # This internally uses user-browser to set the BROWSER environment variable
    __functor = self: arg:
      let
        browser = getBrowser arg;
      in
      if browser == null then
        # No parameter - just return the base aspect
        self
      else
        # Parameter provided - add user-browser to set the default browser
        # Preserve all attributes from self and update includes
        {
          inherit (self) description;
          includes = baseIncludes ++ [ (den._.user-browser browser) ];
        };
  };
}

