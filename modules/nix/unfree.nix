{ lib, den,
  FTS, ... }:
{
  den.provides.unfree.description = ''
    A class generic aspect that enables unfree packages by name or all unfree packages.

    Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

    ## Usage

      # Allow specific unfree packages by name
      FTS.my-laptop.includes = [ (den._.unfree [ "code" "steam" ]) ];

      # Allow all unfree packages
      FTS.my-laptop.includes = [ (den._.unfree true) ];

    It will dynamically provide a module for each class when accessed.
  '';

  den.provides.unfree.__functor =
    _self: arg:
    { class, aspect-chain }:
    let
      config = if arg == true then
        # Enable all unfree packages
        { allowUnfree = true; }
      else if lib.isList arg then
        # Enable specific packages by name
        { allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) arg; }
      else
        throw "unfree: argument must be either 'true' or a list of package names";
    in
    den.lib.take.unused aspect-chain {
      ${class}.nixpkgs.config = config;
    };
}