{ lib, den,
  FTS, ... }:
let
  # Map common browser names to their executable names
  browserMap = {
    firefox = "firefox";
    brave = "brave";
    zen-browser = "zen-browser";
    zen = "zen-browser";
    chromium = "chromium";
    google-chrome = "google-chrome";
    librewolf = "librewolf";
  };

  # Parse browser argument - can be a string or an attrset
  parseBrowser = arg:
    if lib.isString arg then
      {
        browser = browserMap.${arg} or arg;
      }
    else if lib.isAttrs arg then
      {
        browser = arg.browser or (throw "user-browser: 'browser' field is required");
      }
    else
      throw "user-browser: argument must be a string or an attribute set";
in
{
  den.provides.user-browser.description = ''
    Sets a user's preferred browser and BROWSER environment variable.

    Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

    ## Usage

      FTS.vic.includes = [
        (den._.user-browser "firefox")
        # or with custom browser name
        (den._.user-browser { browser = "zen-browser"; })
      ];

    It will dynamically provide a module for each class when accessed.
  '';

  den.provides.user-browser.__functor =
    _self: arg:
    { class, aspect-chain }:
    let
      browserConfig = parseBrowser arg;
      browser = browserConfig.browser;
      
      # Set environment variables based on class
      envVars = {
        BROWSER = browser;
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

