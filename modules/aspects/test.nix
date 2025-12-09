# Test module - demonstrates parametric aspect
# Can add hello and/or cowsay packages based on parameters
# 
# Usage: FTS.test { hello = true; cowsay = true; }
{
  den,
  lib,
  FTS,
  ...
}:
let
  description = ''
    Test module that adds hello and/or cowsay packages based on parameters.
    Demonstrates using native Home Manager and NixOS options with type checking.

    ## Usage

      # Add both packages
      FTS.my-aspect.includes = [ (FTS.test { hello = true; cowsay = true; }) ];

      # Add only hello
      FTS.my-aspect.includes = [ (FTS.test { hello = true; }) ];

      # Add only cowsay
      FTS.my-aspect.includes = [ (FTS.test { cowsay = true; }) ];
  '';

  # Helper to parse and validate arguments
  parseArgs = arg:
    if arg == null || arg == { } then
      { hello = false; cowsay = false; }
    else if lib.isString arg then
      if arg == "hello" then { hello = true; cowsay = false; }
      else if arg == "cowsay" then { hello = false; cowsay = true; }
      else throw "test: string argument must be 'hello' or 'cowsay'"
    else if lib.isAttrs arg then
      {
        hello = arg.hello or false;
        cowsay = arg.cowsay or false;
      }
    else
      throw "test: argument must be a string, attribute set, or null";

  # Home Manager context - adds packages to home.packages
  # Note: We don't declare options here to avoid duplicate declarations
  # The cfg values are used directly, similar to den.provides.unfree
  homeManagerContext = cfg: { pkgs, ... }: {
    home.packages = with pkgs; [
    ] ++ lib.optional cfg.hello hello
      ++ lib.optional cfg.cowsay cowsay;
  };

  # NixOS context - adds packages to environment.systemPackages
  # Note: We don't declare options here to avoid duplicate declarations
  # The cfg values are used directly, similar to den.provides.unfree
  nixosContext = cfg: { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
    ] ++ lib.optional cfg.hello hello
      ++ lib.optional cfg.cowsay cowsay;
  };
in
{
  FTS.test.description = description;

  # Use __functor pattern like the test example from flake-aspects
  # Takes named arguments: { hello = true; cowsay = true; }
  FTS.test.__functor =
    _:
    arg: # args must be always named
    { class, aspect-chain, ... }:
    let
      cfg = parseArgs arg;
    in
    # Only include the context for the current class, like den.provides.unfree
    {
      ${class} = 
        if class == "homeManager" then homeManagerContext cfg
        else if class == "nixos" then nixosContext cfg
        else { };
    };
}

